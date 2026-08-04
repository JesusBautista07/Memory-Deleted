extends Node3D
## Sistema de cámara FPS: rotación horizontal (este nodo) y vertical (Camera3D hijo).
## Responsabilidad única: traducir input de mouse en rotación de cámara,
## y gestionar captura/liberación del cursor.

@export var mouse_sensitivity: float = 0.15
@export var vertical_limit_degrees: float = 89.0

@onready var camera: Camera3D = $Camera3D

var _rotation_x: float = 0.0  # acumulador de rotación vertical, en grados

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_camera(event.relative)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _rotate_camera(mouse_delta: Vector2) -> void:
	# Rotación horizontal: rota este nodo (Head) en Y
	rotate_y(-mouse_delta.x * mouse_sensitivity * 0.01)

	# Rotación vertical: rota solo el Camera3D en X, con límite
	_rotation_x -= mouse_delta.y * mouse_sensitivity
	_rotation_x = clamp(_rotation_x, -vertical_limit_degrees, vertical_limit_degrees)
	camera.rotation_degrees.x = _rotation_x
