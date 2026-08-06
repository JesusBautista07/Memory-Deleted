class_name FollowState
extends AIState

@export var stop_distance: float = 2.0

const ARRIVAL_MARGIN: float = 0.2


func physics_update(delta: float) -> void:
	var origin: Node3D = perception.origin_node
	var target: Node = blackboard.get_value(AIBlackboard.KEY_CURRENT_TARGET, null)
	if origin == null or target == null or not (target is Node3D):
		return

	var target_node: Node3D = target as Node3D
	var direction: Vector3 = target_node.global_position - origin.global_position
	direction.y = 0.0
	var distance: float = direction.length()

	blackboard.set_value(AIBlackboard.KEY_DISTANCE_TO_TARGET, distance)

	if distance <= stop_distance + ARRIVAL_MARGIN:
		return

	var speed: float = data.speed if data != null else 3.0
	origin.global_position += direction.normalized() * speed * delta
	blackboard.set_value(AIBlackboard.KEY_SPEED, speed)
