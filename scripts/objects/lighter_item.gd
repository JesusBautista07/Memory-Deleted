extends PickupObject
class_name LighterItem

signal toggled(is_lit: bool)

@export var fuel_level: float = 1.0
@export var is_lit: bool = false

func toggle() -> void:
	if fuel_level <= 0.0:
		return
	is_lit = not is_lit
	toggled.emit(is_lit)

func set_fuel_level(value: float) -> void:
	fuel_level = clampf(value, 0.0, 1.0)

func get_fuel_level() -> float:
	return fuel_level
