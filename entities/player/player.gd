extends Node3D
class_name Player

@export var halberd: Halberd

@onready var right_xr_controller_3d: XRController3D = $XROrigin3D/RightXRController3D
@onready var left_xr_controller_3d: XRController3D = $XROrigin3D/LeftXRController3D

func _process(_delta: float) -> void:
	var interface = XRServer.find_interface("OpenXR")
	
	if not interface or not interface.is_initialized():
		var debug_hand_pos = Vector3(0, 1.5, -0.5) 
		right_xr_controller_3d.global_position = debug_hand_pos + Vector3(0.2, 0, 0)
		left_xr_controller_3d.global_position = debug_hand_pos + Vector3(-0.2, 0, 0)

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
