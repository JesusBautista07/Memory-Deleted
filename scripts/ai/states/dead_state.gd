class_name DeadState
extends AIState

signal died


func enter(previous_state: AIState) -> void:
	blackboard.set_value(AIBlackboard.KEY_SPEED, 0.0)
	blackboard.clear_value(AIBlackboard.KEY_CURRENT_TARGET)
	died.emit()


func update(delta: float) -> void:
	pass


func physics_update(delta: float) -> void:
	pass


func handle_input(event: InputEvent) -> void:
	pass
