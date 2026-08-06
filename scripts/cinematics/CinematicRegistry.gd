class_name CinematicRegistry
extends RefCounted
## Registro de cinemáticas disponibles.
##
## Responsabilidad única: mantener una colección de CinematicData
## indexada por su cinematic_id, permitiendo registrar, buscar,
## eliminar y consultar. No reproduce, no valida reglas de negocio
## externas y no depende de ningún Manager ni Autoload.
## Es una clase instanciable de forma independiente (no es un singleton).

## Diccionario interno: cinematic_id (StringName) -> CinematicData.
var _entries: Dictionary = {}


## Registra una cinemática en el registro.
## Si ya existe una entrada con el mismo cinematic_id, la reemplaza.
## Devuelve false si el dato es inválido (nulo o sin id) y no la registra.
func register(cinematic_data: CinematicData) -> bool:
	if cinematic_data == null:
		return false
	if cinematic_data.cinematic_id == &"":
		return false

	_entries[cinematic_data.cinematic_id] = cinematic_data
	return true


## Elimina del registro la cinemática asociada a un id.
## Devuelve true si existía y fue eliminada, false en caso contrario.
func unregister(cinematic_id: StringName) -> bool:
	if not _entries.has(cinematic_id):
		return false

	_entries.erase(cinematic_id)
	return true


## Elimina todas las cinemáticas registradas.
func clear() -> void:
	_entries.clear()


## Indica si existe una cinemática registrada con el id dado.
func has_cinematic(cinematic_id: StringName) -> bool:
	return _entries.has(cinematic_id)


## Devuelve el CinematicData asociado a un id, o null si no existe.
func find_by_id(cinematic_id: StringName) -> CinematicData:
	if not _entries.has(cinematic_id):
		return null
	return _entries[cinematic_id]


## Devuelve todas las cinemáticas registradas.
func get_all() -> Array[CinematicData]:
	var result: Array[CinematicData] = []
	for key in _entries.keys():
		result.append(_entries[key])
	return result


## Devuelve todas las cinemáticas registradas que contienen la etiqueta dada.
func find_by_tag(tag: String) -> Array[CinematicData]:
	var result: Array[CinematicData] = []
	for key in _entries.keys():
		var data: CinematicData = _entries[key]
		if data.tags.has(tag):
			result.append(data)
	return result


## Devuelve la cantidad de cinemáticas registradas.
func get_count() -> int:
	return _entries.size()


## Devuelve todos los ids registrados.
func get_all_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for key in _entries.keys():
		result.append(key)
	return result
