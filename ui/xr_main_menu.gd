extends Node3D

var interface: XRInterface

func _ready() -> void:
	interface = XRServer.find_interface("OpenXR")
	if interface and interface.is_initialized():
		get_viewport().use_xr = true
		if interface is OpenXRInterface:
			interface.pose_recentered.connect(func():
				XRServer.center_on_hmd(XRServer.RotationMode.RESET_BUT_KEEP_TILT, true)
			)
