extends Node3D
class_name Note

@export var type: NoteType

@onready var note_model: MeshInstance3D = %NoteModel
@onready var explosion_effect: GPUParticles3D = %ExplosionEffect
@onready var spike_detector: Area3D = %SpikeDetector
@onready var blade_detector: Area3D = %BladeDetector
@onready var pole_detector: Area3D = %PoleDetector

const POINT_TO_ORIGIN_COUNTDOWN = 1.0

var spike_countdown = 0.0
var blade_countdown = 0.0

var approach_time: float
var hit_time: float

var start_position: Vector3
var target_hit_position: Vector3

var node_spawner: NodeSpawner

func _ready() -> void:
	pass

func setup(p_approach_time: float, p_hit_time: float, p_start_pos: Vector3, p_target_pos: Vector3, spawner_ref: NodeSpawner) -> void:
	approach_time = p_approach_time
	hit_time = p_hit_time
	node_spawner = spawner_ref
	
	start_position = p_start_pos
	target_hit_position = p_target_pos
	global_position = start_position
	
	if type:
		if type.material:
			note_model.material_override = type.material
			explosion_effect.material_override = type.material
		
		if type.name in ["pierce", "any"] and not spike_detector.area_entered.is_connected(_on_area_entered):
			spike_detector.area_entered.connect(_on_area_entered)
		if type.name in ["cut", "deflect", "any"] and not blade_detector.area_entered.is_connected(_on_area_entered):
			blade_detector.area_entered.connect(_on_area_entered)
		if type.name in ["bump", "deflect", "any"] and not pole_detector.area_entered.is_connected(_on_area_entered):
			pole_detector.area_entered.connect(_on_area_entered)
	

func _process(delta: float) -> void:
	var current_time = node_spawner.song_timestamp
	
	var time_left = hit_time - current_time
	var progress = 1.0 - (time_left / approach_time)
	
	global_position = start_position.lerp(target_hit_position, progress)
	
	if progress > 1.2:
		queue_free()

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _break():
	note_model.visible = false
	
	explosion_effect.emitting = true
	await explosion_effect.finished
	
	queue_free()

func _on_area_entered(area: Area3D) -> void:
	if not area is HalberdPart: return
	
	match area.part_name:
		"SpikePoint": spike_countdown = POINT_TO_ORIGIN_COUNTDOWN
		"BladePoint": blade_countdown = POINT_TO_ORIGIN_COUNTDOWN
		"PoleOrigin": _break()
		"SpikeOrigin": if spike_countdown > 0:
			spike_countdown = 0
			_break()
		"BladeOrigin": if blade_countdown > 0:
			blade_countdown = 0
			_break()
