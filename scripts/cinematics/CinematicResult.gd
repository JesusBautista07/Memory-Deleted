class_name CinematicResult
extends RefCounted
## Resultado de la ejecución de una cinemática.
##
## Estructura de datos pura: no ejecuta ni controla ninguna reproducción.
## Está pensada para ser construida por sistemas externos (ajenos a este
## módulo) una vez que una cinemática terminó, y luego ser consultada.
## Diseñada para ser ampliada en el futuro sin romper compatibilidad.

## Identificador de la cinemática a la que corresponde este resultado.
var cinematic_id: StringName = &""

## Estado final con el que terminó la cinemática (ver CinematicState).
var final_state: int = CinematicState.NONE

## Indica si la cinemática se considera exitosa (terminó de forma esperada).
var success: bool = false

## Indica si la cinemática fue saltada por el usuario.
var was_skipped: bool = false

## Duración total reproducida, en segundos.
var played_duration: float = 0.0

## Mensaje de error u observación, en caso de fallo (vacío si no aplica).
var error_message: String = ""

## Espacio reservado para datos adicionales de propósito genérico,
## permitiendo ampliar el resultado en el futuro sin romper compatibilidad.
var metadata: Dictionary = {}


func _init(
	p_cinematic_id: StringName = &"",
	p_final_state: int = CinematicState.NONE,
	p_success: bool = false,
	p_was_skipped: bool = false,
	p_played_duration: float = 0.0,
	p_error_message: String = "",
	p_metadata: Dictionary = {}
) -> void:
	cinematic_id = p_cinematic_id
	final_state = p_final_state
	success = p_success
	was_skipped = p_was_skipped
	played_duration = p_played_duration
	error_message = p_error_message
	metadata = p_metadata


## Devuelve una copia de este resultado como un Dictionary de solo lectura.
func to_dictionary() -> Dictionary:
	return {
		"cinematic_id": cinematic_id,
		"final_state": final_state,
		"final_state_name": CinematicState.get_state_name(final_state),
		"success": success,
		"was_skipped": was_skipped,
		"played_duration": played_duration,
		"error_message": error_message,
		"metadata": metadata,
	}
