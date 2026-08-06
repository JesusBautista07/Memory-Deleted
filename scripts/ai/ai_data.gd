class_name AIData
extends Resource

@export var speed: float = 3.0
@export var vision_radius: float = 10.0
@export var hearing_radius: float = 15.0
@export var wait_time: float = 2.0
@export var chase_distance: float = 12.0
@export var attack_distance: float = 1.5

@export var custom_data: Dictionary = {}


func get_custom_value(key: String, default_value: Variant = null) -> Variant:
	return custom_data.get(key, default_value)


func set_custom_value(key: String, value: Variant) -> void:
	custom_data[key] = value
