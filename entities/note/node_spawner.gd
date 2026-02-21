extends Node3D
class_name NodeSpawner

const ANY = preload("uid://cutpon7qvl3ca")
const BUMP = preload("uid://ckscnewigjhk3")
const CUT = preload("uid://e8e40ven26br")
const DEFLECT = preload("uid://c80hllwl12v48")
const PIERCE = preload("uid://bu1dyfn1nctti")
const NOTE = preload("uid://ca5t2d35dmbkh")

var beatmap_notes: Array[Dictionary] = []
@export var song_timestamp: float = 0
@export var height: float = 0

@export_group("Rhythm Settings")
@export var global_approach_time: float = 2.0
@export var spawn_distance: float = 10.0
@export var hit_z_offset: float = -1.0

@export_group("VR Bounds Control")
@export var spacing_scale: Vector2 = Vector2(0.5, 0.5) 
@export var max_bounds: Vector2 = Vector2(1.0, 1.0) 
@export var global_offset: Vector3 = Vector3(-1, 1.2, -0.5) 

var _current_notes_index = 0

func _process(_delta: float) -> void:
	if beatmap_notes.is_empty():
		return
	
	for i in range(beatmap_notes.size() - 1, -1, -1):
		var note_data = beatmap_notes[i]
		
		var approach_time = note_data.get("approach_time", 0.0)
		if approach_time <= 0.0:
			approach_time = global_approach_time
			
		if approach_time <= 0.1:
			approach_time = 2.9
			
		var hit_time = note_data.time
		var spawn_time = hit_time - approach_time
		
		if song_timestamp >= spawn_time:
			_spawn_note(note_data, approach_time, hit_time)
			beatmap_notes.remove_at(i)

func _spawn_note(data: Dictionary, approach_time: float, hit_time: float) -> void:
	var note: Note = NOTE.instantiate()
	
	var x_val = data.get("lane_x", data.get("position_x", 0.0))
	var y_val = data.get("height_y", data.get("position_y", 0.0))
	
	var scaled_x = x_val * spacing_scale.x
	var scaled_y = y_val * spacing_scale.y
	
	var final_x = clamp(scaled_x, -max_bounds.x, max_bounds.x)
	var final_y = clamp(scaled_y, -max_bounds.y, max_bounds.y)
	
	var target_hit_pos = Vector3(
		final_x + global_offset.x, 
		(final_y + height) + global_offset.y, 
		hit_z_offset
	)
	
	var start_pos = target_hit_pos + Vector3(0, 0, -spawn_distance)
	
	match data.type:
		"any": note.type = ANY
		"deflect": note.type = DEFLECT
		"cut": note.type = CUT
		"bump": note.type = BUMP
		"pierce": note.type = PIERCE
		
	get_parent().add_child(note)
	
	note.setup(approach_time, hit_time, start_pos, target_hit_pos, self)
