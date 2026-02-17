extends Node3D
class_name Gameplay

@onready var node_spawner: NodeSpawner = %NodeSpawner

var interface: XRInterface

func _ready() -> void:
	interface = XRServer.find_interface("OpenXR")
	if interface and interface.is_initialized():
		get_viewport().use_xr = true
		if interface is OpenXRInterface:
			interface.pose_recentered.connect(func():
				XRServer.center_on_hmd(XRServer.RotationMode.RESET_BUT_KEEP_TILT, true)
			)

func _process(delta: float) -> void:
	node_spawner.song_timestamp += delta
