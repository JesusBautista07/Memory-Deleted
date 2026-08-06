class_name PatrolState
extends AIState

signal point_reached(index: int)

const KEY_PATROL_POINTS: String = "patrol_points"
const KEY_PATROL_INDEX: String = "patrol_index"

const ARRIVAL_DISTANCE: float = 0.3

var _wait_timer: float = 0.0
var _waiting: bool = false


func enter(previous_state: AIState) -> void:
	_wait_timer = 0.0
	_waiting = false
	if not blackboard.has_value(KEY_PATROL_INDEX):
		blackboard.set_value(KEY_PATROL_INDEX, 0)


func physics_update(delta: float) -> void:
	var origin: Node3D = perception.origin_node
	var points: Array = blackboard.get_value(KEY_PATROL_POINTS, [])
	if origin == null or points.is_empty():
		return

	var index: int = blackboard.get_value(KEY_PATROL_INDEX, 0) as int
	index = index % points.size()
	var target_position: Vector3 = points[index]

	if _waiting:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_waiting = false
			blackboard.set_value(KEY_PATROL_INDEX, (index + 1) % points.size())
		return

	var direction: Vector3 = target_position - origin.global_position
	var distance: float = direction.length()

	if distance <= ARRIVAL_DISTANCE:
		_waiting = true
		_wait_timer = data.wait_time if data != null else 0.0
		point_reached.emit(index)
		return

	var speed: float = data.speed if data != null else 3.0
	origin.global_position += direction.normalized() * speed * delta
	blackboard.set_value(AIBlackboard.KEY_SPEED, speed)
