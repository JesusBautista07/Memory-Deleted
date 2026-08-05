class_name PuzzleManager
extends Node

## Punto único de entrada del sistema de puzzles. Registra, activa,
## reinicia, valida y completa puzzles, y notifica a UI/EventManager
## mediante señales. No abre puertas, no reproduce sonido, no toca
## inventario/documentos directamente: solo comunica.

signal puzzle_registered(id: StringName)
signal puzzle_unregistered(id: StringName)
signal puzzle_activated(id: StringName)
signal puzzle_reset(id: StringName)
signal puzzle_state_changed(id: StringName, new_state: PuzzleData.State)
signal puzzle_solved(id: StringName)
signal puzzle_completed(id: StringName)
signal puzzle_validation_failed(id: StringName)

var _puzzles: Dictionary = {}  # StringName -> Puzzle

## Referencias externas inyectadas (no se buscan por ruta fija para no
## acoplar el sistema a nombres de autoloads del proyecto).
var _event_manager: Node = null
var _inventory: Node = null
var _documents: Node = null

## type: String -> Callable(condition: Dictionary, context: Dictionary) -> bool
var _condition_validators: Dictionary = {}


func _ready() -> void:
	_register_default_condition_validators()


# ---------------------------------------------------------------------------
# Inyección de dependencias (llamar desde el código de integración existente)
# ---------------------------------------------------------------------------

func set_event_manager(event_manager: Node) -> void:
	_event_manager = event_manager


func set_inventory(inventory: Node) -> void:
	_inventory = inventory


func set_documents(documents: Node) -> void:
	_documents = documents


func register_condition_validator(condition_type: String, validator: Callable) -> void:
	_condition_validators[condition_type] = validator


# ---------------------------------------------------------------------------
# Registro y ciclo de vida de puzzles
# ---------------------------------------------------------------------------

func register_puzzle(data: PuzzleData) -> Puzzle:
	if data == null or data.id == &"":
		push_error("PuzzleManager: PuzzleData inválido o sin ID.")
		return null

	if _puzzles.has(data.id):
		push_warning("PuzzleManager: puzzle '%s' ya estaba registrado, se sobrescribe." % data.id)

	var puzzle := Puzzle.new(data, _condition_validators)
	puzzle.state_changed.connect(_on_puzzle_state_changed.bind(data.id))
	puzzle.solved.connect(_on_puzzle_solved.bind(data.id))
	puzzle.completed.connect(_on_puzzle_completed.bind(data.id))

	_puzzles[data.id] = puzzle
	puzzle_registered.emit(data.id)
	return puzzle


func unregister_puzzle(id: StringName) -> void:
	if not _puzzles.has(id):
		return
	var puzzle: Puzzle = _puzzles[id]
	if puzzle.state_changed.is_connected(_on_puzzle_state_changed):
		puzzle.state_changed.disconnect(_on_puzzle_state_changed)
	_puzzles.erase(id)
	puzzle_unregistered.emit(id)


func activate_puzzle(id: StringName) -> void:
	var puzzle := get_puzzle(id)
	if puzzle == null:
		return
	puzzle.activate()
	puzzle_activated.emit(id)


func reset_puzzle(id: StringName) -> void:
	var puzzle := get_puzzle(id)
	if puzzle == null:
		return
	puzzle.reset()
	puzzle_reset.emit(id)


func complete_puzzle(id: StringName) -> void:
	var puzzle := get_puzzle(id)
	if puzzle == null:
		return
	puzzle.mark_completed()


# ---------------------------------------------------------------------------
# Consulta de estado
# ---------------------------------------------------------------------------

func get_puzzle(id: StringName) -> Puzzle:
	return _puzzles.get(id, null)


func has_puzzle(id: StringName) -> bool:
	return _puzzles.has(id)


func is_puzzle_solved(id: StringName) -> bool:
	var puzzle := get_puzzle(id)
	return puzzle != null and puzzle.is_solved()


func get_puzzle_state(id: StringName) -> Variant:
	var puzzle := get_puzzle(id)
	if puzzle == null:
		return null
	return puzzle.get_state()


func get_all_puzzle_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in _puzzles.keys():
		ids.append(id)
	return ids


# ---------------------------------------------------------------------------
# Validación
# ---------------------------------------------------------------------------

## context permite pasar datos puntuales de la comprobación (ej. código
## introducido, orden de interacción registrado) además de lo que el
## manager añade automáticamente (chequeo de inventario).
func validate_puzzle(id: StringName, context: Dictionary = {}) -> bool:
	var puzzle := get_puzzle(id)
	if puzzle == null:
		return false

	var full_context := context.duplicate()
	if not full_context.has("has_item"):
		full_context["has_item"] = Callable(self, "_has_item_in_inventory")

	var result := puzzle.validate_all_conditions(full_context)
	if not result:
		puzzle_validation_failed.emit(id)
	return result


## Valida y, si procede, marca el puzzle como resuelto en un solo paso.
func try_solve_puzzle(id: StringName, context: Dictionary = {}) -> bool:
	if validate_puzzle(id, context):
		complete_puzzle(id)
		return true
	return false


# ---------------------------------------------------------------------------
# Validadores de condiciones por defecto (extensibles vía
# register_condition_validator sin tocar este archivo)
# ---------------------------------------------------------------------------

func _register_default_condition_validators() -> void:
	register_condition_validator("has_item", _validate_has_item)
	register_condition_validator("code", _validate_code)
	register_condition_validator("password", _validate_code)
	register_condition_validator("order", _validate_order)
	register_condition_validator("sequence", _validate_order)
	register_condition_validator("custom", _validate_custom)


func _validate_has_item(condition: Dictionary, _context: Dictionary) -> bool:
	var item_id: StringName = condition.get("item_id", &"")
	if item_id == &"":
		return false
	return _has_item_in_inventory(item_id)


func _validate_code(condition: Dictionary, context: Dictionary) -> bool:
	var expected: String = str(condition.get("expected", ""))
	var entered: String = str(context.get("entered_code", ""))
	return expected != "" and expected == entered


func _validate_order(condition: Dictionary, context: Dictionary) -> bool:
	var expected_sequence: Array = condition.get("sequence", [])
	var actual_sequence: Array = context.get("entered_sequence", [])
	return expected_sequence == actual_sequence


func _validate_custom(condition: Dictionary, context: Dictionary) -> bool:
	var validator: Callable = condition.get("validator", Callable())
	if validator.is_valid():
		return validator.call(condition, context)
	return false


# ---------------------------------------------------------------------------
# Integración con sistemas existentes (solo comunicación, sin implementarlos)
# ---------------------------------------------------------------------------

func _has_item_in_inventory(item_id: StringName) -> bool:
	if _inventory == null:
		return false
	if _inventory.has_method("has_item"):
		return _inventory.has_item(item_id)
	return false


func _notify_event_manager(event_name: StringName, payload: Dictionary) -> void:
	if _event_manager == null or event_name == &"":
		return
	if _event_manager.has_method("trigger_event"):
		_event_manager.trigger_event(event_name, payload)
	elif _event_manager.has_method("emit_event"):
		_event_manager.emit_event(event_name, payload)


# ---------------------------------------------------------------------------
# Callbacks internos de Puzzle -> re-emisión centralizada
# ---------------------------------------------------------------------------

func _on_puzzle_state_changed(new_state: PuzzleData.State, id: StringName) -> void:
	puzzle_state_changed.emit(id, new_state)


func _on_puzzle_solved(id: StringName) -> void:
	puzzle_solved.emit(id)

	var puzzle := get_puzzle(id)
	if puzzle == null:
		return

	_notify_event_manager(puzzle.data.associated_event, {
		"puzzle_id": id,
		"reward": puzzle.data.reward
	})


func _on_puzzle_completed(id: StringName) -> void:
	puzzle_completed.emit(id)
