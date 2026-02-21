extends Resource
class_name BeatmapData

@export_group("Song Info")
@export var full_name: String
@export var technical_name: String
@export var author: String
@export var beatmap_creator: String
@export var difficulty: String
@export var environment_id: String

@export_group("Media")
@export var audio_stream: AudioStream 
@export var cover_texture: Texture2D

@export_group("Stats")
@export var length: float
@export var preview_start: float
@export var preview_end: float
@export var bpm: float

@export_group("Gameplay")
@export var notes: Array[Dictionary] = [] 
@export var global_approach_time: float = 2.9

func parse_json(data: Dictionary) -> void:
	var info = data.get("song_info", {})
	
	full_name = info.get("full_name", "Unknown")
	technical_name = info.get("technical_name", "unknown")
	author = info.get("author", "Unknown")
	beatmap_creator = info.get("beatmap_creator", "Unknown")
	difficulty = info.get("difficulty", "Normal")
	environment_id = info.get("environment_id", "default")
	
	bpm = info.get("bpm", 120.0)
	length = info.get("length", 0.0)
	preview_start = info.get("preview_start", 0.0)
	preview_end = info.get("preview_end", 0.0)
	
	var audio_path = info.get("audio_path", "")
	if audio_path and ResourceLoader.exists(audio_path):
		audio_stream = load(audio_path)
		
	var cover_path = info.get("cover_path", "")
	if cover_path and ResourceLoader.exists(cover_path):
		cover_texture = load(cover_path)
	else:
		cover_path = "res://covers/best-404-pages-768x492.png"
		cover_texture = load(cover_path)
	
	global_approach_time = data.get("global_approach_time", 2.9)
	
	notes.clear()
	var raw_notes = data.get("notes", [])
	for n in raw_notes:
		notes.append({
			"time": float(n.get("time", 0.0)),
			"type": str(n.get("type", "any")),
			"position_x": float(n.get("lane_x", 0.0)),
			"position_y": float(n.get("height_y", 0.0)),
			"approach_time": float(n.get("approach_time", 0.0))
		})
