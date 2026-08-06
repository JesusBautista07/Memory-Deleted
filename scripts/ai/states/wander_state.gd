class_name WanderState
extends AIState

const KEY_WANDER_ORIGIN: String = "wander_origin"
const KEY_WANDER_TARGET: String = "wander_target"

@export var wander_radius: float = 6.0

const ARRIVAL_DISTANCE: float = 0.3

var _wait_timer: float = 0.0
var _waiting: bool = false


func enter(previous_state: AIState) -> void:
	_wait_timer = 0.0
	_waiting = false
	var origin: Node3D = perception.origin_node
	if origin != null and not blackboard.has_value(KEY_WANDER_ORIGIN):
		blackboard.set_value(KEY_WANDER_ORIGIN, origin.global_position)
	_pick_new_target()


func physics_update(delta: float) -> void:
	var origin: Node3D = perception.origin_node
	if origin == null:
		return

	if _waiting:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_waiting = false
			_pick_new_target()
		return

	var target_position: Vector3 = blackboard.get_value(KEY_WANDER_TARGET, origin.global_position)
	var direction: Vector3 = target_position - origin.global_position
	var distance: float = direction.length()

	if distance <= ARRIVAL_DISTANCE:
		_waiting = true
		_wait_timer = data.wait_time if data != null else 0.0
		return

	var speed: float = data.speed if data != null else 3.0
	origin.global_position += direction.normalized() * speed * delta
	blackboard.set_value(AIBlackboard.KEY_SPEED, speed)


func _pick_new_target() -> void:
	var base_position: Vector3 = blackboard.get_value(KEY_WANDER_ORIGIN, Vector3.ZERO)
	var angle: float = randf() * TAU
	var radius: float = randf() * wander_radius
	var offset: Vector3 = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	blackboard.set_value(KEY_WANDER_TARGET, base_position + offset)
