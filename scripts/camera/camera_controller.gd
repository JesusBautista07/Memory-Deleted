extends Node3D
## Sistema de cámara FPS: rotación horizontal (aplicada al Player, nodo padre)
## y rotación vertical (Camera3D hijo).
## Responsabilidad única: traducir input de mouse en rotación de cámara,
## y gestionar captura/liberación del cursor.
##
## El yaw se aplica al padre (Player/CharacterBody3D) y no a este nodo,
## para que player_movement.gd (que mueve según su propio transform.basis)
## se mueva en la dirección hacia donde mira la cámara.

@export var mouse_sensitivity: float = 0.15
@export var vertical_limit_degrees: float = 89.0

@onready var camera: Camera3D = $Camera3D
@onready var _yaw_target: Node3D = get_parent()

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
	# Rotación horizontal: rota al Player (padre) en Y, no a este nodo,
	# para que el movimiento WASD siga la orientación de la cámara.
	_yaw_target.rotate_y(-mouse_delta.x * mouse_sensitivity * 0.01)

	# Rotación vertical: rota solo el Camera3D en X, con límite
	_rotation_x -= mouse_delta.y * mouse_sensitivity
	_rotation_x = clamp(_rotation_x, -vertical_limit_degrees, vertical_limit_degrees)
	camera.rotation_degrees.x = _rotation_x
