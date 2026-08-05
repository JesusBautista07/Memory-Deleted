extends PickupObject
class_name FlashlightItem

signal toggled(is_on: bool)

@export var battery_level: float = 1.0
@export var is_on: bool = false

func toggle() -> void:
	is_on = not is_on
	toggled.emit(is_on)

func set_battery_level(value: float) -> void:
	battery_level = clampf(value, 0.0, 1.0)

func get_battery_level() -> float:
	return battery_level
