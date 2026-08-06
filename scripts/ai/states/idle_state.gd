class_name IdleState
extends AIState


func enter(previous_state: AIState) -> void:
	blackboard.set_value(AIBlackboard.KEY_SPEED, 0.0)


func update(delta: float) -> void:
	pass


func physics_update(delta: float) -> void:
	pass
