class_name CinematicSequence
extends RefCounted
## Estructura completa de una secuencia de cinemática.
##
## Agrupa la línea temporal (CinematicTimeline, que a su vez organiza
## CinematicTrack y CinematicAction) junto con las condiciones
## (CinematicCondition) y eventos (CinematicEvent) declarados para la
## cinemática. Es solo estructura: no reproduce, no evalúa condiciones
## y no ejecuta eventos.

## Identificador de la secuencia (útil para debug, referencias o desuplicado).
var sequence_id: StringName = &""

## Identificador de la cinemática (CinematicData) a la que pertenece
## esta secuencia. Se almacena como referencia libre (StringName),
## sin depender de ningún Registry ni Manager.
var cinematic_id: StringName = &""

## Línea temporal de la secuencia. Puede ser null si aún no fue definida.
var timeline: CinematicTimeline = null

## Colección de condiciones declaradas para esta secuencia.
var _conditions: Array[CinematicCondition] = []

## Colección de eventos declarados para esta secuencia.
var _events: Array[CinematicEvent] = []

## Datos adicionales de propósito genérico, para extensión futura.
var metadata: Dictionary = {}


func _init(
	p_sequence_id: StringName = &"",
	p_cinematic_id: StringName = &"",
	p_timeline: CinematicTimeline = null,
	p_metadata: Dictionary = {}
) -> void:
	sequence_id = p_sequence_id
	cinematic_id = p_cinematic_id
	timeline = p_timeline
	metadata = p_metadata


## Asigna la línea temporal de la secuencia.
func set_timeline(p_timeline: CinematicTimeline) -> void:
	timeline = p_timeline


## Devuelve la línea temporal de la secuencia (puede ser null).
func get_timeline() -> CinematicTimeline:
	return timeline


## Añade una condición a la secuencia. Devuelve false si es nula.
func add_condition(condition: CinematicCondition) -> bool:
	if condition == null:
		return false

	_conditions.append(condition)
	return true


## Elimina la primera condición encontrada con el condition_id dado.
func remove_condition(condition_id: StringName) -> bool:
	for i in _conditions.size():
		if _conditions[i].condition_id == condition_id:
			_conditions.remove_at(i)
			return true
	return false


## Devuelve todas las condiciones declaradas en esta secuencia.
func get_conditions() -> Array[CinematicCondition]:
	return _conditions.duplicate()


## Añade un evento a la secuencia. Devuelve false si es nulo.
func add_event(event: CinematicEvent) -> bool:
	if event == null:
		return false

	_events.append(event)
	return true


## Elimina el primer evento encontrado con el event_id dado.
func remove_event(event_id: StringName) -> bool:
	for i in _events.size():
		if _events[i].event_id == event_id:
			_events.remove_at(i)
			return true
	return false


## Devuelve todos los eventos declarados en esta secuencia.
func get_events() -> Array[CinematicEvent]:
	return _events.duplicate()


## Devuelve la duración total de la secuencia según su línea temporal
## (0.0 si no tiene timeline asignada). Cálculo puramente derivado.
func get_duration() -> float:
	if timeline == null:
		return 0.0
	return timeline.get_duration()
