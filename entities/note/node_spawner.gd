extends Node3D
class_name NodeSpawner

const ANY = preload("uid://cutpon7qvl3ca")
const BUMP = preload("uid://ckscnewigjhk3")
const CUT = preload("uid://e8e40ven26br")
const DEFLECT = preload("uid://c80hllwl12v48")
const PIERCE = preload("uid://bu1dyfn1nctti")

const NOTE = preload("uid://ca5t2d35dmbkh")

var current_beatmap: BeatmapData
@export var note_direction: Vector3 = Vector3.BACK
@export var song_timestamp: float = 0
@export var height: float = 0

var _current_notes_index = 0

func _process(_delta: float) -> void:
	if not current_beatmap: return
	
	var notes = current_beatmap.notes
	
	while _current_notes_index < notes.size() and song_timestamp >= notes[_current_notes_index].time:
		_spawn_note(notes[_current_notes_index])
		_current_notes_index += 1

func _spawn_note(data: Dictionary):
	var note: Note = NOTE.instantiate()
	note.velocity = note_direction
	note.position = Vector3(data.position_x, data.position_y + height, position.z)
	match data.type:
		"any": note.type = ANY
		"deflect": note.type = DEFLECT
		"cut": note.type = CUT
		"bump": note.type = BUMP
		"pierce": note.type = PIERCE
	get_parent().add_child(note)
