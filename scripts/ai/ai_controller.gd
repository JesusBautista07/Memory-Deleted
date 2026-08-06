class_name AIController
extends Node

signal state_changed(previous_name: String, new_name: String)

@export var data: AIData
@export var initial_state: String = ""
@export var origin_node_path: NodePath

var state_machine: AIStateMachine
var blackboard: AIBlackboard
var perception: AIPerception


func _ready() -> void:
	state_machine = AIStateMachine.new()
	add_child(state_machine)
	state_machine.setup(self)
	state_machine.state_changed.connect(_on_state_machine_state_changed)

	blackboard = AIBlackboard.new()
	add_child(blackboard)

	perception = AIPerception.new()
	add_child(perception)

	var origin_node: Node3D = null
	if not origin_node_path.is_empty():
		origin_node = get_node_or_null(origin_node_path)
	elif get_parent() is Node3D:
		origin_node = get_parent()
	perception.setup(origin_node)

	if data != null:
		blackboard.set_value(AIBlackboard.KEY_SPEED, data.speed)
		blackboard.set_value(AIBlackboard.KEY_WAIT_TIME, data.wait_time)

	if not initial_state.is_empty():
		change_state(initial_state)


func add_state(state_name: String, state: AIState) -> void:
	state_machine.add_state(state_name, state)


func change_state(state_name: String) -> void:
	state_machine.change_state(state_name)


func get_current_state_name() -> String:
	return state_machine.get_current_state_name()


func update(delta: float) -> void:
	state_machine.update(delta)


func physics_update(delta: float) -> void:
	state_machine.physics_update(delta)


func handle_input(event: InputEvent) -> void:
	state_machine.handle_input(event)


func _on_state_machine_state_changed(previous_name: String, new_name: String) -> void:
	state_changed.emit(previous_name, new_name)
