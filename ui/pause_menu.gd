extends Control

signal resume_requested
signal restart_requested
signal quit_requested

@onready var title_label: Label = %SongTitle
@onready var diff_label: Label = %SongDiff
@onready var cover_rect: TextureRect = %SongCover

func setup(beatmap: BeatmapData) -> void:
	if not beatmap: return
	
	title_label.text = beatmap.full_name
	diff_label.text = beatmap.difficulty
	if beatmap.cover_texture:
		cover_rect.texture = beatmap.cover_texture

func _on_resume_pressed() -> void:
	resume_requested.emit()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/song_selector.tscn")
