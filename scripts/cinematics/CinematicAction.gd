class_name CinematicAction
extends RefCounted
## Estructura de una acción dentro de una cinemática.
##
## Representa la descripción de una única acción (ej: mover cámara,
## mostrar diálogo, hacer fade, etc.) en términos puramente de datos:
## cuándo ocurre, cuánto dura y con qué parámetros. No la ejecuta,
## no la interpola y no la valida; eso es responsabilidad de un
## sistema externo ajeno a este módulo.

## Identificador de la acción (útil para debug, referencias o desuplicado).
var action_id: StringName = &""

## Identificador del tipo de acción (ej: "camera_move", "show_dialog",
## "fade_in"). Se define de forma libre para no acoplarse a ningún
## sistema concreto.
var action_type: StringName = &""

## Momento, en segundos, dentro de la pista en que la acción comienza.
var start_time: float = 0.0

## Duración, en segundos, de la acción. 0.0 representa una acción instantánea.
var duration: float = 0.0

## Parámetros de la acción, de propósito genérico (clave -> valor libre).
var parameters: Dictionary = {}

## Indica si la acción es opcional (podría omitirse sin afectar la cinemática).
var is_optional: bool = false

## Datos adicionales de propósito genérico, para extensión futura.
var metadata: Dictionary = {}


func _init(
	p_action_id: StringName = &"",
	p_action_type: StringName = &"",
	p_start_time: float = 0.0,
	p_duration: float = 0.0,
	p_parameters: Dictionary = {},
	p_is_optional: bool = false,
	p_metadata: Dictionary = {}
) -> void:
	action_id = p_action_id
	action_type = p_action_type
	start_time = p_start_time
	duration = p_duration
	parameters = p_parameters
	is_optional = p_is_optional
	metadata = p_metadata


## Momento, en segundos, en que la acción finaliza (start_time + duration).
## Cálculo puramente derivado de los datos ya contenidos, sin lógica externa.
func get_end_time() -> float:
	return start_time + duration


## Devuelve el valor de un parámetro de la acción, o default si no existe.
func get_parameter(key: String, default_value: Variant = null) -> Variant:
	return parameters.get(key, default_value)


## Devuelve una copia de esta acción como un Dictionary de solo lectura.
func to_dictionary() -> Dictionary:
	return {
		"action_id": action_id,
		"action_type": action_type,
		"start_time": start_time,
		"duration": duration,
		"parameters": parameters,
		"is_optional": is_optional,
		"metadata": metadata,
	}
