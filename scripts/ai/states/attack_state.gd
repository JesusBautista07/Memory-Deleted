class_name AttackState
extends AIState

signal attack_ready
signal target_out_of_range

@export var attack_cooldown: float = 1.0

var _cooldown_timer: float = 0.0


func enter(previous_state: AIState) -> void:
	_cooldown_timer = 0.0


func physics_update(delta: float) -> void:
	var origin: Node3D = perception.origin_node
	var target: Node = blackboard.get_value(AIBlackboard.KEY_CURRENT_TARGET, null)
	if origin == null or target == null or not (target is Node3D):
		return

	var target_node: Node3D = target as Node3D
	var direction: Vector3 = target_node.global_position - origin.global_position
	direction.y = 0.0

	if direction.length() > 0.01:
		origin.look_at(origin.global_position + direction, Vector3.UP)

	var attack_distance: float = data.attack_distance if data != null else 1.5
	if direction.length() > attack_distance:
		target_out_of_range.emit()
		return

	_cooldown_timer -= delta
	if _cooldown_timer <= 0.0:
		_cooldown_timer = attack_cooldown
		attack_ready.emit()
