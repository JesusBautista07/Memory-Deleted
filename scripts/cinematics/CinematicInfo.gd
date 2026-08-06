class_name CinematicInfo
extends RefCounted
## Información resumida de una cinemática, de solo consulta.
##
## No controla ni ejecuta nada. Es una fotografía de datos (snapshot)
## pensada para ser leída por sistemas externos (UI, logs, debug, etc.)
## sin exponer ni depender del Resource original ni de ningún Manager.

## Identificador de la cinemática a la que corresponde esta información.
var cinematic_id: StringName = &""

## Nombre legible de la cinemática.
var display_name: String = ""

## Estado actual conocido de la cinemática (ver CinematicState).
var state: int = CinematicState.NONE

## Duración total conocida de la cinemática, en segundos.
var duration: float = 0.0

## Tiempo transcurrido conocido, en segundos (informativo, no se actualiza aquí).
var elapsed_time: float = 0.0

## Indica si, según la información disponible, la cinemática puede saltarse.
var is_skippable: bool = true

## Indica si, según la información disponible, ya fue reproducida antes.
var has_been_played: bool = false

## Etiquetas asociadas a la cinemática (copia informativa).
var tags: PackedStringArray = PackedStringArray()


func _init(
	p_cinematic_id: StringName = &"",
	p_display_name: String = "",
	p_state: int = CinematicState.NONE,
	p_duration: float = 0.0,
	p_elapsed_time: float = 0.0,
	p_is_skippable: bool = true,
	p_has_been_played: bool = false,
	p_tags: PackedStringArray = PackedStringArray()
) -> void:
	cinematic_id = p_cinematic_id
	display_name = p_display_name
	state = p_state
	duration = p_duration
	elapsed_time = p_elapsed_time
	is_skippable = p_is_skippable
	has_been_played = p_has_been_played
	tags = p_tags


## Progreso normalizado (0.0 - 1.0) en base a duration/elapsed_time.
## Cálculo puramente derivado de los datos ya contenidos, sin lógica externa.
func get_progress() -> float:
	if duration <= 0.0:
		return 0.0
	return clampf(elapsed_time / duration, 0.0, 1.0)


## Devuelve una copia de esta información como un Dictionary de solo lectura.
func to_dictionary() -> Dictionary:
	return {
		"cinematic_id": cinematic_id,
		"display_name": display_name,
		"state": state,
		"state_name": CinematicState.get_state_name(state),
		"duration": duration,
		"elapsed_time": elapsed_time,
		"is_skippable": is_skippable,
		"has_been_played": has_been_played,
		"tags": tags,
	}
