class_name InvestigateState
extends AIState

signal finished

const ARRIVAL_DISTANCE: float = 0.4


func physics_update(delta: float) -> void:
	var origin: Node3D = perception.origin_node
	if origin == null or not blackboard.has_value(AIBlackboard.KEY_LAST_KNOWN_POSITION):
		finished.emit()
		return

	var target_position: Vector3 = blackboard.get_value(AIBlackboard.KEY_LAST_KNOWN_POSITION)
	var direction: Vector3 = target_position - origin.global_position
	var distance: float = direction.length()

	if distance <= ARRIVAL_DISTANCE:
		finished.emit()
		return

	var speed: float = data.speed if data != null else 3.0
	origin.global_position += direction.normalized() * speed * delta
	blackboard.set_value(AIBlackboard.KEY_SPEED, speed)
