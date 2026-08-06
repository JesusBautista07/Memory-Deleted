class_name ChaseState
extends AIState

signal target_in_attack_range
signal target_lost_during_chase


func physics_update(delta: float) -> void:
	var origin: Node3D = perception.origin_node
	var target: Node = blackboard.get_value(AIBlackboard.KEY_CURRENT_TARGET, null)
	if origin == null or target == null or not (target is Node3D):
		target_lost_during_chase.emit()
		return

	var target_node: Node3D = target as Node3D
	blackboard.set_value(AIBlackboard.KEY_LAST_KNOWN_POSITION, target_node.global_position)

	var direction: Vector3 = target_node.global_position - origin.global_position
	direction.y = 0.0
	var distance: float = direction.length()
	blackboard.set_value(AIBlackboard.KEY_DISTANCE_TO_TARGET, distance)

	var attack_distance: float = data.attack_distance if data != null else 1.5
	if distance <= attack_distance:
		target_in_attack_range.emit()
		return

	var chase_distance: float = data.chase_distance if data != null else 12.0
	if distance > chase_distance:
		target_lost_during_chase.emit()
		return

	var speed: float = data.speed if data != null else 3.0
	origin.global_position += direction.normalized() * speed * delta
	blackboard.set_value(AIBlackboard.KEY_SPEED, speed)
