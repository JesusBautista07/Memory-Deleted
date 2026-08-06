class_name AIStateMachine
extends Node

signal state_changed(previous_name: String, new_name: String)

var controller: AIController

var _states: Dictionary = {}
var _current_state: AIState
var _current_state_name: String = ""


func setup(p_controller: AIController) -> void:
	controller = p_controller


func add_state(state_name: String, state: AIState) -> void:
	state.setup(controller)
	_states[state_name] = state


func remove_state(state_name: String) -> void:
	_states.erase(state_name)


func has_state(state_name: String) -> bool:
	return _states.has(state_name)


func get_state(state_name: String) -> AIState:
	return _states.get(state_name, null)


func get_current_state() -> AIState:
	return _current_state


func get_current_state_name() -> String:
	return _current_state_name


func change_state(state_name: String) -> void:
	if not _states.has(state_name):
		push_warning("AIStateMachine: estado no registrado '%s'" % state_name)
		return

	var next_state: AIState = _states[state_name]
	var previous_state: AIState = _current_state
	var previous_name: String = _current_state_name

	if previous_state != null:
		previous_state.exit(next_state)

	_current_state = next_state
	_current_state_name = state_name
	_current_state.enter(previous_state)

	state_changed.emit(previous_name, state_name)


func update(delta: float) -> void:
	if _current_state != null:
		_current_state.update(delta)


func physics_update(delta: float) -> void:
	if _current_state != null:
		_current_state.physics_update(delta)


func handle_input(event: InputEvent) -> void:
	if _current_state != null:
		_current_state.handle_input(event)
