extends Resource
class_name BeatmapData

@export_group("Song Info")
@export var full_name: String
@export var technical_name: String
@export var author: String
@export var difficulty: String
@export var audio_stream: AudioStream 

@export_group("Gameplay")
@export var notes: Array[Dictionary] = [] 

func parse_json(data: Dictionary) -> void:
	var info = data.get("song_info", {})
	full_name = info.get("full_name", "Unknown")
	technical_name = info.get("technical_name", "unknown")
	author = info.get("author", "Unknown")
	difficulty = info.get("difficulty", "Normal")
	
	var audio_path = info.get("audio_path", "")
	if audio_path and ResourceLoader.exists(audio_path):
		audio_stream = load(audio_path)
	
	notes.clear()
	var raw_notes = data.get("notes", [])
	for n in raw_notes:
		notes.append({
			"time": n.get("time", 0.0),
			"type": n.get("type", "any"),
			"position_x": n.get("lane_x", 0.0),
			"position_y": n.get("height_y", 0.0)
		})
