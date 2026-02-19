extends Camera3D

@export var sensitivity: float = 0.003
@export var move_speed: float = 2.0

func _ready() -> void:
	var interface = XRServer.find_interface("OpenXR")
	if interface and interface.is_initialized():
		current = false
		set_process(false)
		set_process_input(false)
		queue_free()
	else:
		current = true
		position = Vector3(0, 1.7, 0)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * sensitivity
		rotation.x -= event.relative.y * sensitivity
		rotation.x = clamp(rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		global_position += direction * move_speed * delta
