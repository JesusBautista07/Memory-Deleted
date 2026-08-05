class_name PuzzleData
extends Resource

## Recurso de datos para un puzzle. No contiene lógica, solo definición.

enum Type {
	SWITCH,
	LEVER,
	BUTTON_COMBINATION,
	NUMERIC_CODE,
	PASSWORD,
	REQUIRED_OBJECTS,
	SPECIAL_KEY,
	INTERACTION_ORDER,
	SEQUENCE,
	TIMER,
	CUSTOM
}

enum State {
	NOT_STARTED,
	ACTIVE,
	SOLVED
}

@export var id: StringName = &""
@export var puzzle_name: String = ""
@export var description: String = ""
@export var type: Type = Type.CUSTOM
@export var state: State = State.NOT_STARTED

## Cada condición es un Dictionary libre, ej:
## {"type": "has_item", "item_id": "key_01"}
## {"type": "code", "expected": "1984"}
## {"type": "order", "sequence": ["a","b","c"]}
## {"type": "custom", "id": "my_check", "params": {}}
@export var conditions: Array[Dictionary] = []

## IDs de objetos/items requeridos por el inventario existente.
@export var required_items: Array[StringName] = []

## Nombre del evento existente a emitir al EventManager al resolverse.
@export var associated_event: StringName = &""

## Datos libres de recompensa (item a otorgar, flag, etc.), interpretados
## por los sistemas existentes, no por este sistema de puzzles.
@export var reward: Dictionary = {}
