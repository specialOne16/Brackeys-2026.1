extends Node3D
class_name NodeSpawner

const CUT = preload("uid://ck1fbulp3abgg")
const PIERCE = preload("uid://6mvghlctlk5k")

const NOTE = preload("uid://ca5t2d35dmbkh")

@export var note_direction: Vector3 = Vector3.BACK
@export var song_timestamp: float = 0
@export var height: float = 0

const notes = [
	{
		"time": 1.0,
		"position_x": 0.5,
		"position_y": 0.5,
		"type": "cut"
	},
	{
		"time": 2.0,
		"position_x": -0.5,
		"position_y": 0.5,
		"type": "pierce"
	}
]

var _current_notes_index = 0

func _process(_delta: float) -> void:
	while _current_notes_index < notes.size() and song_timestamp >= notes[_current_notes_index].time:
		_spawn_note(notes[_current_notes_index])
		_current_notes_index += 1

func _spawn_note(data: Dictionary):
	var note: Note = NOTE.instantiate()
	note.velocity = note_direction
	note.position = Vector3(data.position_x, data.position_y + height, position.z)
	match data.type:
		"pierce": note.material = PIERCE
		"cur": note.material = CUT
	get_parent().add_child(note)
