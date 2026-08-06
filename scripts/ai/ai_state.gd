class_name AIState
extends Node

var controller: AIController
var blackboard: AIBlackboard
var perception: AIPerception
var data: AIData


func setup(p_controller: AIController) -> void:
	controller = p_controller
	blackboard = p_controller.blackboard
	perception = p_controller.perception
	data = p_controller.data


func enter(previous_state: AIState) -> void:
	pass


func exit(next_state: AIState) -> void:
	pass


func update(delta: float) -> void:
	pass


func physics_update(delta: float) -> void:
	pass


func handle_input(event: InputEvent) -> void:
	pass
