class_name CinematicTimeline
extends RefCounted
## Estructura de la línea temporal completa de una cinemática.
##
## Administra una colección de CinematicTrack. No reproduce, no
## actualiza y no controla ningún tiempo real; solo organiza la
## estructura de pistas como datos.

## Identificador de la línea temporal (útil para debug o referencias).
var timeline_id: StringName = &""

## Nombre legible de la línea temporal (para editor, debug o UI).
var display_name: String = ""

## Colección de pistas que pertenecen a esta línea temporal.
var _tracks: Array[CinematicTrack] = []

## Datos adicionales de propósito genérico, para extensión futura.
var metadata: Dictionary = {}


func _init(
	p_timeline_id: StringName = &"",
	p_display_name: String = "",
	p_metadata: Dictionary = {}
) -> void:
	timeline_id = p_timeline_id
	display_name = p_display_name
	metadata = p_metadata


## Añade una pista a la línea temporal. Devuelve false si la pista es nula.
func add_track(track: CinematicTrack) -> bool:
	if track == null:
		return false

	_tracks.append(track)
	return true


## Elimina la primera pista encontrada con el track_id dado.
## Devuelve true si existía y fue eliminada, false en caso contrario.
func remove_track(track_id: StringName) -> bool:
	for i in _tracks.size():
		if _tracks[i].track_id == track_id:
			_tracks.remove_at(i)
			return true
	return false


## Elimina todas las pistas de la línea temporal.
func clear_tracks() -> void:
	_tracks.clear()


## Devuelve la pista asociada a un track_id, o null si no existe.
func find_track(track_id: StringName) -> CinematicTrack:
	for track in _tracks:
		if track.track_id == track_id:
			return track
	return null


## Devuelve todas las pistas almacenadas en esta línea temporal.
func get_tracks() -> Array[CinematicTrack]:
	return _tracks.duplicate()


## Devuelve todas las pistas cuyo track_type coincide con el dado.
func find_tracks_by_type(track_type: StringName) -> Array[CinematicTrack]:
	var result: Array[CinematicTrack] = []
	for track in _tracks:
		if track.track_type == track_type:
			result.append(track)
	return result


## Devuelve la cantidad de pistas almacenadas en esta línea temporal.
func get_track_count() -> int:
	return _tracks.size()


## Devuelve el momento, en segundos, en que finaliza la pista más larga
## (0.0 si no hay pistas). Cálculo puramente derivado, sin control de tiempo.
func get_duration() -> float:
	var max_duration: float = 0.0
	for track in _tracks:
		max_duration = maxf(max_duration, track.get_duration())
	return max_duration
