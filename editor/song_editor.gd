extends Control

# -- UI References (assign these in the inspector or name nodes strictly) --
@export var audio_player: AudioStreamPlayer
@export var timeline_slider: HSlider
@export var time_label: Label
@export var grid_container: GridContainer
@export var type_selector: OptionButton
@export var bpm_input: SpinBox
@export var snap_checkbox: CheckBox
@export var beatmap_name_input: LineEdit

# -- Data --
var current_notes: Array[Dictionary] = []
var current_beatmap_path: String = "res://beatmaps/custom_map.json"
var song_duration: float = 0.0
var dragging_timeline: bool = false
var playback_speed: float = 1.0

# -- Constants --
const GRID_COLUMNS = 4 # Lanes
const GRID_ROWS = 3    # Height
const NOTE_TYPES = ["any", "cut", "bump", "deflect", "pierce"]

func _ready() -> void:
	_setup_ui()
	_setup_grid()
	
	# Try to load the default song for context
	if audio_player.stream:
		song_duration = audio_player.stream.get_length()
		timeline_slider.max_value = song_duration

func _process(delta: float) -> void:
	if audio_player.playing and not dragging_timeline:
		timeline_slider.value = audio_player.get_playback_position()
	
	_update_time_display()
	_refresh_grid_visuals()

# --- UI Setup ---
func _setup_ui() -> void:
	# Populate Note Types
	#type_selector.clear()
	for type in NOTE_TYPES:
		type_selector.add_item(type.capitalize())
	
	# Connect signals
	timeline_slider.drag_started.connect(func(): dragging_timeline = true)
	timeline_slider.drag_ended.connect(_on_timeline_drag_ended)
	
	# Set default BPM if none
	if bpm_input.value == 0:
		bpm_input.value = 120

func _setup_grid() -> void:
	# Clear existing
	for child in grid_container.get_children():
		child.queue_free()
	
	grid_container.columns = GRID_COLUMNS
	
	# Create buttons for 4x3 grid (inverted Y so 0 is bottom)
	for y in range(GRID_ROWS - 1, -1, -1): # 2, 1, 0
		for x in range(GRID_COLUMNS):      # 0, 1, 2, 3
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(60, 60)
			btn.toggle_mode = true
			btn.name = "Cell_%d_%d" % [x, y]
			btn.pressed.connect(_on_grid_cell_pressed.bind(x, y))
			grid_container.add_child(btn)

# --- Interactions ---

func _on_play_pause_pressed() -> void:
	if audio_player.playing:
		audio_player.stop()
	else:
		audio_player.play(timeline_slider.value)

func _on_timeline_drag_ended(value_changed: bool) -> void:
	dragging_timeline = false
	var time = timeline_slider.value
	
	# Snap logic
	if snap_checkbox.button_pressed and bpm_input.value > 0:
		time = _quantize_time(time)
		timeline_slider.value = time
		
	if audio_player.playing:
		audio_player.play(time)
	else:
		# Just set position for visual update
		audio_player.seek(time)

func _on_grid_cell_pressed(x: int, y: int) -> void:
	var current_time = timeline_slider.value
	var type_index = type_selector.selected
	var type_str = NOTE_TYPES[type_index]
	
	# Check if note exists roughly at this time and location
	var existing_index = _find_note_index(current_time, x, y)
	
	if existing_index != -1:
		# If clicked and exists, remove it (Toggle off)
		current_notes.remove_at(existing_index)
	else:
		# Add new note
		var note = {
			"time": current_time,
			"lane_x": float(x),
			"height_y": float(y),
			"type": type_str
		}
		current_notes.append(note)
		# Sort by time to keep things tidy
		current_notes.sort_custom(func(a, b): return a.time < b.time)

# --- Logic ---

func _quantize_time(time: float) -> float:
	var bpm = bpm_input.value
	if bpm <= 0: return time
	
	var seconds_per_beat = 60.0 / bpm
	var step = seconds_per_beat / 2.0 # Snap to 8th notes (half beats)
	
	return round(time / step) * step

func _find_note_index(time: float, x: int, y: int) -> int:
	# Fuzzy search for time (within 0.05s)
	var tolerance = 0.05
	for i in range(current_notes.size()):
		var n = current_notes[i]
		if n.lane_x == x and n.height_y == y and abs(n.time - time) < tolerance:
			return i
	return -1

func _refresh_grid_visuals() -> void:
	var current_time = timeline_slider.value
	
	for y in range(GRID_ROWS):
		for x in range(GRID_COLUMNS):
			# Determine visual state based on if a note exists here NOW
			var idx = _find_note_index(current_time, x, y)
			
			# Find the button in the grid container
			# Note: Grid container children are linear. 
			# Loop was: y from 2 down to 0, x from 0 to 3.
			var child_idx = ((GRID_ROWS - 1 - y) * GRID_COLUMNS) + x
			var btn = grid_container.get_child(child_idx) as Button
			
			if idx != -1:
				btn.text = current_notes[idx].type.left(2).to_upper()
				btn.modulate = Color.GREEN
			else:
				btn.text = ""
				btn.modulate = Color.WHITE

func _update_time_display() -> void:
	var m = int(timeline_slider.value / 60)
	var s = int(timeline_slider.value) % 60
	var ms = int((timeline_slider.value - int(timeline_slider.value)) * 100)
	time_label.text = "%02d:%02d:%02d" % [m, s, ms]

# --- File I/O ---

func save_beatmap() -> void:
	var data = {
		"_meta": { "version": "1.0" },
		"song_info": {
			"full_name": beatmap_name_input.text,
			"technical_name": beatmap_name_input.text.to_lower().replace(" ", "_"),
			"audio_path": audio_player.stream.resource_path if audio_player.stream else ""
		},
		"notes": current_notes
	}
	
	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open("res://beatmaps/" + beatmap_name_input.text + ".json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		print("Saved to " + file.get_path_absolute())
	else:
		push_error("Failed to save file")

func load_beatmap(path: String) -> void:
	if not FileAccess.file_exists(path): return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	if err == OK:
		var data = json.data
		current_notes.clear()
		for n in data.get("notes", []):
			# Ensure float types
			n.time = float(n.time)
			n.lane_x = float(n.lane_x)
			n.height_y = float(n.height_y)
			current_notes.append(n)
		
		beatmap_name_input.text = data.get("song_info", {}).get("full_name", "Unknown")
		print("Loaded " + str(current_notes.size()) + " notes.")


func _on_save_button_pressed() -> void:
	save_beatmap()

func _on_load_button_pressed() -> void:
	load_beatmap("res://beatmaps/guardina_normal.json")


func _on_play_button_pressed() -> void:
	_on_play_pause_pressed()
