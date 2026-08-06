class_name CinematicEvent
extends RefCounted
## Estructura de un evento asociado a una cinemática.
##
## Únicamente almacena la información necesaria para describir un
## evento que ocurriría durante la reproducción (cuándo y qué datos
## lleva). No lo ejecuta: la ejecución es responsabilidad de un
## sistema externo ajeno a este módulo.

## Identificador del evento (útil para debug, referencias o desuplicado).
var event_id: StringName = &""

## Identificador del tipo de evento (ej: "play_sound", "spawn_vfx", "shake").
## Se define de forma libre para no acoplarse a ningún sistema concreto.
var event_type: StringName = &""

## Momento, en segundos, dentro de la cinemática en que el evento debería
## dispararse. Es un dato puramente informativo en este módulo.
var trigger_time: float = 0.0

## Parámetros del evento, de propósito genérico (clave -> valor libre).
var parameters: Dictionary = {}

## Indica si el evento es opcional (podría omitirse sin afectar la cinemática).
var is_optional: bool = false

## Prioridad relativa del evento (uso libre para quien lo consuma).
var priority: int = 0

## Datos adicionales de propósito genérico, para extensión futura.
var metadata: Dictionary = {}


func _init(
	p_event_id: StringName = &"",
	p_event_type: StringName = &"",
	p_trigger_time: float = 0.0,
	p_parameters: Dictionary = {},
	p_is_optional: bool = false,
	p_priority: int = 0,
	p_metadata: Dictionary = {}
) -> void:
	event_id = p_event_id
	event_type = p_event_type
	trigger_time = p_trigger_time
	parameters = p_parameters
	is_optional = p_is_optional
	priority = p_priority
	metadata = p_metadata


## Devuelve el valor de un parámetro del evento, o default si no existe.
func get_parameter(key: String, default_value: Variant = null) -> Variant:
	return parameters.get(key, default_value)


## Devuelve una copia de este evento como un Dictionary de solo lectura.
func to_dictionary() -> Dictionary:
	return {
		"event_id": event_id,
		"event_type": event_type,
		"trigger_time": trigger_time,
		"parameters": parameters,
		"is_optional": is_optional,
		"priority": priority,
		"metadata": metadata,
	}
