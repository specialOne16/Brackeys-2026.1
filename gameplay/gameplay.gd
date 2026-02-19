extends Node3D
class_name Gameplay

@onready var node_spawner: NodeSpawner = %NodeSpawner
@onready var audio_player: AudioStreamPlayer = $GuardianOfTheAlps

var interface: XRInterface

func _ready() -> void:
	interface = XRServer.find_interface("OpenXR")
	if interface and interface.is_initialized():
		get_viewport().use_xr = true
		if interface is OpenXRInterface:
			interface.pose_recentered.connect(func():
				XRServer.center_on_hmd(XRServer.RotationMode.RESET_BUT_KEEP_TILT, true)
			)
			
	# --- TO DO ---
	# In the future, this should come from our song selection menu 
	var beatmap = BeatmapLoader.load_beatmap("res://beatmaps/guardian_normal.json")
	
	node_spawner.beatmap_notes = beatmap.notes
	
	if beatmap.audio_stream:
		audio_player.stream = beatmap.audio_stream
		audio_player.play()


func _process(delta: float) -> void:
	if audio_player.playing:
		node_spawner.song_timestamp = audio_player.get_playback_position()
	else:
		node_spawner.song_timestamp += delta
