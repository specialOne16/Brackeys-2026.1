extends Control

@export_group("Playback")
@export var audio_player: AudioStreamPlayer
@export var timeline_slider: HSlider
@export var time_label: Label
@export var play_button: Button
@export var prev_note_button: Button
@export var next_note_button: Button

@export_group("Grid")
@export var grid_container: GridContainer
@export var type_selector: OptionButton
@export var snap_checkbox: CheckBox
@export var bpm_input: SpinBox
@export var grid_rows_input: SpinBox
@export var grid_cols_input: SpinBox

@export_group("Metadata")
@export var filename_input: LineEdit
@export var title_input: LineEdit
@export var author_input: LineEdit
@export var difficulty_input: OptionButton 
@export var audio_path_input: LineEdit

@export_group("Extended Metadata")
@export var creator_input: LineEdit
@export var cover_path_input: LineEdit
@export var env_input: LineEdit
@export var preview_start_input: SpinBox
@export var preview_end_input: SpinBox
@export var file_dialog: FileDialog

@export var generator_popup: Window
@export var generate_button: Button
@export var clear_button: Button

var current_notes: Array[Dictionary] = []
var song_duration: float = 0.0
var dragging_timeline: bool = false
var current_file_mode: int = 0

const NOTE_TYPES = ["any", "cut", "bump", "deflect", "pierce"]
const DIFFICULTIES = ["Easy", "Normal", "Hard", "Expert"]
enum FileMode { LOAD_JSON, AUDIO, COVER }

func _ready() -> void:
	_setup_ui()
		
	grid_rows_input.value_changed.connect(func(_v): _setup_grid())
	grid_cols_input.value_changed.connect(func(_v): _setup_grid())
		
	audio_path_input.text_submitted.connect(_on_audio_path_submitted)
	
	if clear_button:
		clear_button.pressed.connect(_on_clear_button_pressed)
	
	if not audio_path_input.text.is_empty():
		_on_audio_path_submitted(audio_path_input.text)
	_setup_grid()
	
	generate_button.pressed.connect(_on_generate_button_pressed)	
	if generator_popup.has_signal("notes_generated"):
		generator_popup.notes_generated.connect(_on_notes_generated_received)

func _process(_delta: float) -> void:
	if audio_player.playing and not dragging_timeline:
		timeline_slider.value = audio_player.get_playback_position()
	
	_update_time_display()
	_refresh_grid_visuals()

func _setup_ui() -> void:	
	type_selector.clear()
	for type in NOTE_TYPES:
		type_selector.add_item(type.capitalize())
		
	difficulty_input.clear()
	for diff in DIFFICULTIES:
		difficulty_input.add_item(diff)
		
	timeline_slider.drag_started.connect(func(): dragging_timeline = true)
	timeline_slider.drag_ended.connect(_on_timeline_drag_ended)
	play_button.pressed.connect(_on_play_pause_pressed)
	prev_note_button.pressed.connect(_on_prev_note_pressed)
	next_note_button.pressed.connect(_on_next_note_pressed)
		
	if bpm_input.value == 0: bpm_input.value = 120
	if grid_rows_input.value == 0: grid_rows_input.value = 3
	if grid_cols_input.value == 0: grid_cols_input.value = 4

func _setup_grid() -> void:	
	for child in grid_container.get_children():
		child.queue_free()
	
	var cols = int(grid_cols_input.value)
	var rows = int(grid_rows_input.value)
	
	grid_container.columns = cols
		
	for y in range(rows - 1, -1, -1): 
		for x in range(cols):      
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(60, 60)
			btn.toggle_mode = true
			btn.name = "Cell_%d_%d" % [x, y]
			btn.focus_mode = Control.FOCUS_NONE 
			btn.pressed.connect(_on_grid_cell_pressed.bind(x, y))
			grid_container.add_child(btn)


func _on_load_button_pressed() -> void:
	current_file_mode = FileMode.LOAD_JSON
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.json ; Beatmap JSON"]
	file_dialog.popup_centered()

func _on_browse_audio_pressed() -> void:
	current_file_mode = FileMode.AUDIO
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.wav, *.ogg, *.mp3 ; Audio Files"]
	file_dialog.popup_centered()

func _on_browse_cover_pressed() -> void:
	current_file_mode = FileMode.COVER
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.png, *.jpg, *.jpeg ; Images"]
	file_dialog.popup_centered()

func _on_file_dialog_file_selected(path: String) -> void:
	match current_file_mode:
		FileMode.LOAD_JSON:
			_load_beatmap_from_file(path)
		FileMode.AUDIO:
			audio_path_input.text = path
			_on_audio_path_submitted(path)
		FileMode.COVER:
			cover_path_input.text = path


func _on_audio_path_submitted(path_text: String) -> void:
	if path_text.is_empty(): return
	
	var stream: AudioStream = null
		
	if path_text.begins_with("res://"):
		if FileAccess.file_exists(path_text):
			stream = load(path_text)
		
	else:
		stream = _load_external_audio(path_text)
		
	if stream:
		audio_player.stream = stream
		song_duration = stream.get_length()
		timeline_slider.max_value = song_duration		
		if preview_end_input.value == 0:
			preview_end_input.value = song_duration
		print("Audio Loaded: ", path_text)
	else:
		push_error("Could not load audio file: " + path_text)

func _load_external_audio(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		return null
		
	if path.ends_with(".ogg"):
		return AudioStreamOggVorbis.load_from_file(path)
	elif path.ends_with(".mp3"):
		var file = FileAccess.open(path, FileAccess.READ)
		var sound = AudioStreamMP3.new()
		sound.data = file.get_buffer(file.get_length())
		return sound
	elif path.ends_with(".wav"):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			push_warning("Loading external WAVs might not work in exported builds. Use OGG/MP3.")
			var s = load(path)
			if s: return s
	return null


func _on_play_pause_pressed() -> void:
	if audio_player.playing:
		audio_player.stop()
	else:
		if audio_player.stream:
			audio_player.play(timeline_slider.value)

func _on_prev_note_pressed() -> void:
	if current_notes.is_empty(): return
	
	var current_time = timeline_slider.value
	var target_time = -1.0
		
	for i in range(current_notes.size() - 1, -1, -1):
		var t = current_notes[i].time
		if t < current_time - 0.01:
			target_time = t
			break
	
	if target_time != -1.0:
		_seek_to(target_time)

func _on_next_note_pressed() -> void:
	if current_notes.is_empty(): return
	
	var current_time = timeline_slider.value
	var target_time = -1.0
		
	for note in current_notes:
		var t = note.time
		if t > current_time + 0.01:
			target_time = t
			break
	
	if target_time != -1.0:
		_seek_to(target_time)

func _seek_to(time: float) -> void:
	timeline_slider.value = time
	if audio_player.playing:
		audio_player.play(time)
	else:
		audio_player.seek(time)
		
	_refresh_grid_visuals()

func _on_timeline_drag_ended(_value_changed: bool) -> void:
	dragging_timeline = false
	var time = timeline_slider.value
	
	if snap_checkbox.button_pressed and bpm_input.value > 0:
		time = _quantize_time(time)
		timeline_slider.value = time
		
	if audio_player.playing:
		audio_player.play(time)
	else:
		audio_player.seek(time)

func _on_grid_cell_pressed(x: int, y: int) -> void:
	var current_time = timeline_slider.value
	var type_index = type_selector.selected
	var type_str = NOTE_TYPES[type_index]
	
	var idx = _find_note_index(current_time, x, y)
	
	if idx != -1:
		current_notes.remove_at(idx)
	else:
		var note = {
			"time": current_time,
			"lane_x": float(x),
			"height_y": float(y),
			"type": type_str
		}
		current_notes.append(note)
		current_notes.sort_custom(func(a, b): return a.time < b.time)


func _quantize_time(time: float) -> float:
	var bpm = bpm_input.value
	if bpm <= 0: return time
	var seconds_per_beat = 60.0 / bpm
	var step = seconds_per_beat / 2.0 
	return round(time / step) * step

func _find_note_index(time: float, x: int, y: int) -> int:
	var tolerance = 0.05
	for i in range(current_notes.size()):
		var n = current_notes[i]
		if n.lane_x == x and n.height_y == y and abs(n.time - time) < tolerance:
			return i
	return -1

func _refresh_grid_visuals() -> void:
	var current_time = timeline_slider.value
	var cols = int(grid_cols_input.value)
	var rows = int(grid_rows_input.value)
	
	if grid_container.get_child_count() != cols * rows:
		return

	for y in range(rows):
		for x in range(cols):
			var idx = _find_note_index(current_time, x, y)
			var child_idx = ((rows - 1 - y) * cols) + x
			if child_idx < grid_container.get_child_count():
				var btn = grid_container.get_child(child_idx) as Button
				if idx != -1:
					btn.text = current_notes[idx].type.left(2).to_upper()
					btn.modulate = Color.GREEN
					btn.set_pressed_no_signal(true)
				else:
					btn.text = ""
					btn.modulate = Color.WHITE
					btn.set_pressed_no_signal(false)

func _update_time_display() -> void:
	var m = int(timeline_slider.value / 60)
	var s = int(timeline_slider.value) % 60
	var ms = int((timeline_slider.value - int(timeline_slider.value)) * 100)
	time_label.text = "%02d:%02d:%02d" % [m, s, ms]


func _on_save_button_pressed() -> void:
	save_beatmap()

func _load_beatmap_from_file(path: String) -> void:
	if not FileAccess.file_exists(path): 
		push_warning("File not found: " + path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var data = json.data
		var info = data.get("song_info", {})
				
		title_input.text = info.get("full_name", "")
		filename_input.text = info.get("technical_name", "")
		author_input.text = info.get("author", "")
		creator_input.text = info.get("beatmap_creator", "")
		audio_path_input.text = info.get("audio_path", "")
		cover_path_input.text = info.get("cover_path", "")
		env_input.text = info.get("environment_id", "default")
				
		bpm_input.value = info.get("bpm", 120)
		preview_start_input.value = info.get("preview_start", 0)
		preview_end_input.value = info.get("preview_end", 0)
				
		var diff = info.get("difficulty", "Normal")
		var diff_idx = DIFFICULTIES.find(diff)
		if diff_idx != -1: difficulty_input.selected = diff_idx
				
		var grid = info.get("grid_size", {})
		grid_rows_input.value = grid.get("rows", 3)
		grid_cols_input.value = grid.get("cols", 4)
				
		current_notes.clear()
		for n in data.get("notes", []):
			n.time = float(n.time)
			n.lane_x = float(n.lane_x)
			n.height_y = float(n.height_y)
			current_notes.append(n)
					
		_on_audio_path_submitted(audio_path_input.text)
		_setup_grid()
		print("Loaded beatmap: ", path)

func save_beatmap() -> void:
	var diff_str = DIFFICULTIES[difficulty_input.selected]
	
	var data = {
		"_meta": { "version": "1.2" },
		"song_info": {
			"full_name": title_input.text,
			"technical_name": filename_input.text,
			"author": author_input.text,
			"beatmap_creator": creator_input.text,
			"difficulty": diff_str,
			"audio_path": audio_path_input.text,
			"cover_path": cover_path_input.text,
			"environment_id": env_input.text,
			"bpm": bpm_input.value,
			"length": song_duration,
			"preview_start": preview_start_input.value,
			"preview_end": preview_end_input.value,
			"grid_size": {
				"rows": grid_rows_input.value,
				"cols": grid_cols_input.value
			}
		},
		"notes": current_notes
	}
	
	var json_string = JSON.stringify(data, "\t")
	var path = "res://beatmaps/" + filename_input.text + ".json"
	
	if not DirAccess.dir_exists_absolute("res://beatmaps"):
		DirAccess.make_dir_absolute("res://beatmaps")
		
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		print("Saved beatmap to ", path)
	else:
		push_error("Failed to save file at " + path)


func _on_generate_button_pressed() -> void:
	if not audio_player.stream:
		print("Load audio first!")
		return
		
	if generator_popup.has_method("setup"):
		generator_popup.setup(
			audio_player.stream,
			bpm_input.value,
			song_duration,
			int(grid_cols_input.value),
			int(grid_rows_input.value)
		)

func _on_notes_generated_received(new_notes: Array[Dictionary]) -> void:		
	current_notes = new_notes
	current_notes.sort_custom(func(a, b): return a.time < b.time)
	_refresh_grid_visuals()
	print("Generated ", current_notes.size(), " notes automatically.")


func _on_clear_button_pressed() -> void:	
	current_notes.clear()
	_refresh_grid_visuals()
	print("All notes cleared.")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
