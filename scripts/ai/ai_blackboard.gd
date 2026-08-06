class_name AIBlackboard
extends Node

signal value_changed(key: String, value: Variant)
signal value_cleared(key: String)

const KEY_CURRENT_TARGET: String = "current_target"
const KEY_LAST_KNOWN_POSITION: String = "last_known_position"
const KEY_WAIT_TIME: String = "wait_time"
const KEY_SPEED: String = "speed"
const KEY_DISTANCE_TO_TARGET: String = "distance_to_target"

var _values: Dictionary = {}


func set_value(key: String, value: Variant) -> void:
	_values[key] = value
	value_changed.emit(key, value)


func get_value(key: String, default_value: Variant = null) -> Variant:
	return _values.get(key, default_value)


func has_value(key: String) -> bool:
	return _values.has(key)


func clear_value(key: String) -> void:
	if _values.has(key):
		_values.erase(key)
		value_cleared.emit(key)


func clear_all() -> void:
	var keys := _values.keys()
	_values.clear()
	for key in keys:
		value_cleared.emit(key)


func get_all_values() -> Dictionary:
	return _values.duplicate()
