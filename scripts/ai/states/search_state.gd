class_name SearchState
extends AIState

signal finished

@export var search_radius: float = 4.0

const ARRIVAL_DISTANCE: float = 0.3

var _timer: float = 0.0
var _current_point: Vector3
var _has_point: bool = false


func enter(previous_state: AIState) -> void:
	_timer = data.wait_time if data != null else 4.0
	_has_point = false


func physics_update(delta: float) -> void:
	var origin: Node3D = perception.origin_node
	if origin == null:
		return

	_timer -= delta
	if _timer <= 0.0:
		finished.emit()
		return

	if not _has_point:
		_pick_point(origin.global_position)

	var direction: Vector3 = _current_point - origin.global_position
	var distance: float = direction.length()

	if distance <= ARRIVAL_DISTANCE:
		_has_point = false
		return

	var speed: float = data.speed if data != null else 3.0
	origin.global_position += direction.normalized() * speed * delta
	blackboard.set_value(AIBlackboard.KEY_SPEED, speed)


func _pick_point(center: Vector3) -> void:
	var angle: float = randf() * TAU
	var radius: float = randf() * search_radius
	_current_point = center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	_has_point = true
