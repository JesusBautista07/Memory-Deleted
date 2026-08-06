class_name LookState
extends AIState

signal finished

@export var turn_speed_degrees: float = 90.0

var _timer: float = 0.0
var _direction: float = 1.0


func enter(previous_state: AIState) -> void:
	_timer = data.wait_time if data != null else 2.0
	_direction = 1.0 if randi() % 2 == 0 else -1.0


func physics_update(delta: float) -> void:
	var origin: Node3D = perception.origin_node
	if origin != null:
		origin.rotate_y(deg_to_rad(turn_speed_degrees) * _direction * delta)

	_timer -= delta
	if _timer <= 0.0:
		finished.emit()
