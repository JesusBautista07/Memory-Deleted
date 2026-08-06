class_name FleeState
extends AIState

signal safe_distance_reached

@export var safe_distance: float = 15.0


func physics_update(delta: float) -> void:
	var origin: Node3D = perception.origin_node
	var threat: Node = blackboard.get_value(AIBlackboard.KEY_CURRENT_TARGET, null)
	if origin == null or threat == null or not (threat is Node3D):
		return

	var threat_node: Node3D = threat as Node3D
	var direction: Vector3 = origin.global_position - threat_node.global_position
	direction.y = 0.0
	var distance: float = direction.length()

	blackboard.set_value(AIBlackboard.KEY_DISTANCE_TO_TARGET, distance)

	if distance >= safe_distance:
		safe_distance_reached.emit()
		return

	if direction.length() < 0.01:
		return

	var speed: float = data.speed if data != null else 3.0
	origin.global_position += direction.normalized() * speed * delta
	blackboard.set_value(AIBlackboard.KEY_SPEED, speed)
