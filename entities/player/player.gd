extends Node3D
class_name Player

@export var halberd: Halberd

@onready var right_xr_controller_3d: XRController3D = $XROrigin3D/RightXRController3D
@onready var left_xr_controller_3d: XRController3D = $XROrigin3D/LeftXRController3D

func _process(_delta: float) -> void:
	halberd.look_at_from_position(
		(right_xr_controller_3d.global_position + left_xr_controller_3d.global_position) / 2,
		right_xr_controller_3d.global_position
	)


func _on_right_xr_controller_3d_button_pressed(a_name: String) -> void:
	if a_name == "trigger_click":
		get_tree().reload_current_scene()


func _on_left_xr_controller_3d_button_pressed(a_name: String) -> void:
	if a_name == "trigger_click":
		get_tree().reload_current_scene()
