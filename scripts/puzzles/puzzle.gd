class_name Puzzle
extends RefCounted

## Instancia en tiempo de ejecución de un puzzle. Envuelve un PuzzleData
## y expone control de estado y validación. No conoce a otros puzzles
## ni al manager; toda orquestación vive en PuzzleManager.

signal state_changed(new_state: PuzzleData.State)
signal activated
signal reset_done
signal solved
signal completed

var data: PuzzleData

## Callable(condition: Dictionary, context: Dictionary) -> bool
## Inyectado por PuzzleManager según el tipo de condición.
var _condition_validators: Dictionary = {}

## Resultado individual por índice de condición, usado por
## puzzles de tipo secuencia/orden que necesitan progreso parcial.
var _condition_progress: Dictionary = {}


func _init(puzzle_data: PuzzleData, condition_validators: Dictionary = {}) -> void:
	data = puzzle_data
	_condition_validators = condition_validators


func get_id() -> StringName:
	return data.id


func get_state() -> PuzzleData.State:
	return data.state


func is_solved() -> bool:
	return data.state == PuzzleData.State.SOLVED


func is_active() -> bool:
	return data.state == PuzzleData.State.ACTIVE


func activate() -> void:
	if data.state == PuzzleData.State.SOLVED:
		return
	_set_state(PuzzleData.State.ACTIVE)
	activated.emit()


func reset() -> void:
	_condition_progress.clear()
	_set_state(PuzzleData.State.NOT_STARTED)
	reset_done.emit()


func mark_completed() -> void:
	_set_state(PuzzleData.State.SOLVED)
	solved.emit()
	completed.emit()


## Valida todas las condiciones del puzzle contra un contexto externo
## (inventario, flags, secuencias registradas, etc). No muta estado.
func validate_all_conditions(context: Dictionary = {}) -> bool:
	if data.conditions.is_empty():
		return _validate_required_items(context)

	for condition in data.conditions:
		if not validate_condition(condition, context):
			return false

	return _validate_required_items(context)


func validate_condition(condition: Dictionary, context: Dictionary = {}) -> bool:
	var condition_type: String = condition.get("type", "")
	var validator: Callable = _condition_validators.get(condition_type, Callable())

	if validator.is_valid():
		return validator.call(condition, context)

	push_warning("Puzzle '%s': no hay validador registrado para condición '%s'" % [data.id, condition_type])
	return false


func _validate_required_items(context: Dictionary) -> bool:
	if data.required_items.is_empty():
		return true

	var has_item_check: Callable = context.get("has_item", Callable())
	if not has_item_check.is_valid():
		return false

	for item_id in data.required_items:
		if not has_item_check.call(item_id):
			return false

	return true


func set_condition_progress(condition_index: int, value: Variant) -> void:
	_condition_progress[condition_index] = value


func get_condition_progress(condition_index: int) -> Variant:
	return _condition_progress.get(condition_index, null)


func _set_state(new_state: PuzzleData.State) -> void:
	if data.state == new_state:
		return
	data.state = new_state
	state_changed.emit(new_state)
