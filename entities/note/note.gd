extends Node3D
class_name Note

@export var material: StandardMaterial3D
@export var velocity: Vector3

@onready var note_model: MeshInstance3D = %NoteModel
@onready var explosion_effect: GPUParticles3D = %ExplosionEffect
@onready var spike_detector: Area3D = %SpikeDetector
@onready var blade_detector: Area3D = %BladeDetector

const POINT_TO_ORIGIN_COUNTDOWN = 1.0

var spike_countdown = 0.0
var blade_countdown = 0.0

func _ready() -> void:
	note_model.material_override = material
	explosion_effect.material_override = material
	
	spike_detector.area_entered.connect(_on_area_entered)
	blade_detector.area_entered.connect(_on_area_entered)

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
		"SpikeOrigin": if spike_countdown > 0:
			spike_countdown = 0
			_break()
		"BladeOrigin": if blade_countdown > 0:
			blade_countdown = 0
			_break()
