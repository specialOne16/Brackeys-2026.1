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
			
	var path_to_load = GameManager.selected_beatmap_path
	var beatmap = BeatmapLoader.load_beatmap(path_to_load)
	
	if beatmap == null:
		print("Warning: Using fallback song!")
		path_to_load = "res://beatmaps/guardian_normal.json"
		beatmap = BeatmapLoader.load_beatmap(path_to_load)
	
	node_spawner.beatmap_notes = beatmap.notes
	node_spawner.global_approach_time = beatmap.global_approach_time
	
	if beatmap.audio_stream:
		audio_player.stream = beatmap.audio_stream
		audio_player.play()


func _process(delta: float) -> void:
	if audio_player.playing:
		node_spawner.song_timestamp = audio_player.get_playback_position()
	else:
		node_spawner.song_timestamp += delta
