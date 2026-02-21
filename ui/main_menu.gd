extends Control

@onready var quit_dialog: ConfirmationDialog = $QuitDialog

func _ready() -> void:
	quit_dialog.hide()

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/xr_song_selector.tscn")

func _on_editor_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/editor/song_editor.tscn")

func _on_settings_button_pressed() -> void:
	print("Settings opening... (To be implemented)")

func _on_quit_button_pressed() -> void:
	quit_dialog.popup_centered()

func _on_quit_dialog_confirmed() -> void:
	get_tree().quit()
