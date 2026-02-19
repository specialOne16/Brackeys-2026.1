extends Control

@onready var song_list_vbox: VBoxContainer = %SongListVBox
@onready var right_half: Control = %RightHalf

@onready var cover_rect: TextureRect = %BigCover
@onready var title_label: Label = %SongTitle
@onready var author_label: Label = %SongAuthor
@onready var notes_count_label: Label = %NoteCount
@onready var nps_label: Label = %NPSLabel

var available_beatmaps: Array[BeatmapData] = []
var selected_beatmap: BeatmapData = null

func _ready() -> void:
	right_half.hide()
	_load_all_beatmaps()
	_populate_song_list()

func _load_all_beatmaps() -> void:
	var dir = DirAccess.open("res://beatmaps/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var path = "res://beatmaps/" + file_name
				var beatmap = BeatmapLoader.load_beatmap(path)
				if beatmap:
					available_beatmaps.append(beatmap)
			file_name = dir.get_next()
			
	available_beatmaps.sort_custom(func(a, b): return a.full_name < b.full_name)

func _populate_song_list() -> void:
	# Clear placeholder UI
	for child in song_list_vbox.get_children():
		child.queue_free()
		
	for beatmap in available_beatmaps:
		var btn = Button.new()
		var mins = int(beatmap.length) / 60
		var secs = int(beatmap.length) % 60
		btn.text = "%s by %s (%02d:%02d)" % [beatmap.full_name, beatmap.author, mins, secs]
		
		btn.custom_minimum_size = Vector2(0, 50)
		btn.pressed.connect(_on_song_clicked.bind(beatmap))
		song_list_vbox.add_child(btn)

func _on_song_clicked(beatmap: BeatmapData) -> void:
	selected_beatmap = beatmap
	
	title_label.text = beatmap.full_name
	author_label.text = beatmap.author
	
	var note_count = beatmap.notes.size()
	notes_count_label.text = "Notes: " + str(note_count)
	
	if beatmap.length > 0:
		var nps = float(note_count) / beatmap.length
		nps_label.text = "NPS: %.2f" % nps
	else:
		nps_label.text = "NPS: 0.0"
		
	if beatmap.cover_texture:
		cover_rect.texture = beatmap.cover_texture
	else:
		cover_rect.texture = null
		
	right_half.show()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_play_pressed() -> void:
	if selected_beatmap:
		GameManager.selected_beatmap_path = "res://beatmaps/" + selected_beatmap.technical_name + ".json"
		get_tree().change_scene_to_file("res://gameplay/gameplay.tscn")
	else:
		print("No song selected!")
