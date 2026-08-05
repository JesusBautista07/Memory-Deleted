extends Node
class_name EventManager
## Infraestructura base del sistema de eventos.
## No implementa lógica de diálogos, cinemáticas, sonido, iluminación,
## enemigos, recuerdos, puertas ni puzles: solo emite las señales
## correspondientes para que esos sistemas se conecten después.
##
## No es un autoload (no se modifica project.godot). Para que
## EventTrigger u otros nodos lo encuentren sin acoplarse a él,
## esta instancia se añade al grupo "event_manager".

signal dialog_requested(event_id: String, payload: Dictionary)
signal cutscene_requested(event_id: String, payload: Dictionary)
signal sound_requested(event_id: String, payload: Dictionary)
signal lighting_requested(event_id: String, payload: Dictionary)
signal enemy_requested(event_id: String, payload: Dictionary)
signal memory_requested(event_id: String, payload: Dictionary)
signal door_requested(event_id: String, payload: Dictionary)
signal puzzle_requested(event_id: String, payload: Dictionary)
signal custom_event_requested(event_id: String, payload: Dictionary)

signal event_registered(event_id: String)
signal event_triggered(event_id: String)

enum EventType {
	DIALOG,
	CUTSCENE,
	SOUND,
	LIGHTING,
	ENEMY,
	MEMORY,
	DOOR,
	PUZZLE,
	CUSTOM,
}

const GROUP_NAME := "event_manager"

var _events: Dictionary = {}  # id: String -> Dictionary(type, payload, once, triggered)


func _ready() -> void:
	add_to_group(GROUP_NAME)


func register_event(event_id: String, type: EventType, payload: Dictionary = {}, once: bool = false) -> bool:
	if event_id.is_empty():
		return false

	_events[event_id] = {
		"type": type,
		"payload": payload,
		"once": once,
		"triggered": false,
	}
	event_registered.emit(event_id)
	return true


func has_event(event_id: String) -> bool:
	return _events.has(event_id)


func trigger_event(event_id: String) -> bool:
	if not has_event(event_id):
		return false

	var event: Dictionary = _events[event_id]

	if event.once and event.triggered:
		return false

	event.triggered = true
	_emit_event_signal(event_id, event.type, event.payload)
	event_triggered.emit(event_id)
	return true


func trigger_events(event_ids: Array) -> void:
	for event_id in event_ids:
		trigger_event(event_id)


func reset_event(event_id: String) -> bool:
	if not has_event(event_id):
		return false

	_events[event_id].triggered = false
	return true


func is_event_triggered(event_id: String) -> bool:
	if not has_event(event_id):
		return false

	return _events[event_id].triggered


func _emit_event_signal(event_id: String, type: EventType, payload: Dictionary) -> void:
	match type:
		EventType.DIALOG:
			dialog_requested.emit(event_id, payload)
		EventType.CUTSCENE:
			cutscene_requested.emit(event_id, payload)
		EventType.SOUND:
			sound_requested.emit(event_id, payload)
		EventType.LIGHTING:
			lighting_requested.emit(event_id, payload)
		EventType.ENEMY:
			enemy_requested.emit(event_id, payload)
		EventType.MEMORY:
			memory_requested.emit(event_id, payload)
		EventType.DOOR:
			door_requested.emit(event_id, payload)
		EventType.PUZZLE:
			puzzle_requested.emit(event_id, payload)
		EventType.CUSTOM:
			custom_event_requested.emit(event_id, payload)
