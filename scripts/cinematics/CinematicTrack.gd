class_name CinematicTrack
extends RefCounted
## Estructura de una pista dentro de la línea temporal de una cinemática.
##
## Almacena y organiza múltiples CinematicAction. No las reproduce, no
## las ordena en tiempo real ni las evalúa; solo administra la colección
## como estructura de datos.

## Identificador de la pista (útil para debug, referencias o desuplicado).
var track_id: StringName = &""

## Identificador del tipo de pista (ej: "camera", "audio", "dialogue",
## "vfx"). Se define de forma libre para no acoplarse a ningún sistema
## concreto.
var track_type: StringName = &""

## Nombre legible de la pista (para editor, debug o UI).
var display_name: String = ""

## Indica si la pista está habilitada (uso libre para quien la consuma).
var is_enabled: bool = true

## Colección de acciones que pertenecen a esta pista.
var _actions: Array[CinematicAction] = []

## Datos adicionales de propósito genérico, para extensión futura.
var metadata: Dictionary = {}


func _init(
	p_track_id: StringName = &"",
	p_track_type: StringName = &"",
	p_display_name: String = "",
	p_is_enabled: bool = true,
	p_metadata: Dictionary = {}
) -> void:
	track_id = p_track_id
	track_type = p_track_type
	display_name = p_display_name
	is_enabled = p_is_enabled
	metadata = p_metadata


## Añade una acción a la pista. Devuelve false si la acción es nula.
func add_action(action: CinematicAction) -> bool:
	if action == null:
		return false

	_actions.append(action)
	return true


## Elimina la primera acción encontrada con el action_id dado.
## Devuelve true si existía y fue eliminada, false en caso contrario.
func remove_action(action_id: StringName) -> bool:
	for i in _actions.size():
		if _actions[i].action_id == action_id:
			_actions.remove_at(i)
			return true
	return false


## Elimina todas las acciones de la pista.
func clear_actions() -> void:
	_actions.clear()


## Devuelve la acción asociada a un action_id, o null si no existe.
func find_action(action_id: StringName) -> CinematicAction:
	for action in _actions:
		if action.action_id == action_id:
			return action
	return null


## Devuelve todas las acciones almacenadas en esta pista.
func get_actions() -> Array[CinematicAction]:
	return _actions.duplicate()


## Devuelve la cantidad de acciones almacenadas en esta pista.
func get_action_count() -> int:
	return _actions.size()


## Devuelve el momento, en segundos, en que finaliza la última acción
## de la pista (0.0 si no hay acciones). Cálculo puramente derivado.
func get_duration() -> float:
	var max_end_time: float = 0.0
	for action in _actions:
		max_end_time = maxf(max_end_time, action.get_end_time())
	return max_end_time
