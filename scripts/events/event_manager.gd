extends Node
class_name EventManager

signal event_triggered(event_id: String, payload: Dictionary)
signal event_registered(event_id: String)
signal event_completed(event_id: String)

enum EventCategory {
	NONE,
	ZONE,
	DIALOGUE,
	CINEMATIC,
	LIGHTING,
	SOUND,
	ENEMY,
	MEMORY,
}

var _registered_events: Dictionary = {}
var _completed_events: Dictionary = {}
var _category_handlers: Dictionary = {}

func register_event(event_id: String, category: EventCategory = EventCategory.NONE, data: Dictionary = {}) -> void:
	if event_id.is_empty():
		return

	_registered_events[event_id] = {
		"category": category,
		"data": data,
	}
	event_registered.emit(event_id)

func unregister_event(event_id: String) -> void:
	_registered_events.erase(event_id)

func is_event_registered(event_id: String) -> bool:
	return _registered_events.has(event_id)

func has_event_completed(event_id: String) -> bool:
	return _completed_events.has(event_id)

func trigger_event(event_id: String, payload: Dictionary = {}) -> void:
	if event_id.is_empty():
		return

	if not _registered_events.has(event_id):
		register_event(event_id)

	event_triggered.emit(event_id, payload)
	_dispatch_to_category(event_id, payload)

func complete_event(event_id: String) -> void:
	_completed_events[event_id] = true
	event_completed.emit(event_id)

func get_event_category(event_id: String) -> EventCategory:
	if not _registered_events.has(event_id):
		return EventCategory.NONE
	return _registered_events[event_id]["category"]

func get_event_data(event_id: String) -> Dictionary:
	if not _registered_events.has(event_id):
		return {}
	return _registered_events[event_id]["data"]

func register_category_handler(category: EventCategory, handler: Callable) -> void:
	_category_handlers[category] = handler

func unregister_category_handler(category: EventCategory) -> void:
	_category_handlers.erase(category)

func _dispatch_to_category(event_id: String, payload: Dictionary) -> void:
	var category: EventCategory = get_event_category(event_id)

	if not _category_handlers.has(category):
		return

	var handler: Callable = _category_handlers[category]
	if handler.is_valid():
		handler.call(event_id, payload)
