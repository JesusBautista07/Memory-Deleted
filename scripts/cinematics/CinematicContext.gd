class_name CinematicContext
extends RefCounted
## Contexto asociado a una reproducción de cinemática.
##
## Almacena únicamente la información contextual con la que una
## cinemática podría ejecutarse (quién la solicitó, variables,
## referencias externas genéricas, etc.). No controla, no valida
## y no ejecuta ninguna reproducción; es solo un contenedor de datos.

## Identificador de la cinemática a la que corresponde este contexto.
var cinematic_id: StringName = &""

## Identificador de quién/qué solicitó la reproducción (libre, sin
## acoplarse a ningún sistema concreto: puede ser un nombre, un id, etc.).
var requester_id: StringName = &""

## Identificador de la escena u origen desde el cual se solicitó la cinemática.
var origin_id: StringName = &""

## Variables de contexto de propósito genérico (clave -> valor libre),
## utilizables por quien consuma este contexto para parametrizar la
## reproducción (ej: nombre del jugador, elecciones previas, flags).
var variables: Dictionary = {}

## Referencias externas genéricas relevantes para la reproducción,
## almacenadas de forma desacoplada (ej: paths, ids, no nodos concretos).
var references: Dictionary = {}

## Indica si el contexto permite que la cinemática sea saltada,
## independientemente de si la cinemática en sí lo permite.
var allow_skip: bool = true

## Marca de tiempo (o valor numérico libre) asociada a la creación del contexto.
var timestamp: float = 0.0

## Datos adicionales de propósito genérico, para extensión futura.
var metadata: Dictionary = {}


func _init(
	p_cinematic_id: StringName = &"",
	p_requester_id: StringName = &"",
	p_origin_id: StringName = &"",
	p_variables: Dictionary = {},
	p_references: Dictionary = {},
	p_allow_skip: bool = true,
	p_timestamp: float = 0.0,
	p_metadata: Dictionary = {}
) -> void:
	cinematic_id = p_cinematic_id
	requester_id = p_requester_id
	origin_id = p_origin_id
	variables = p_variables
	references = p_references
	allow_skip = p_allow_skip
	timestamp = p_timestamp
	metadata = p_metadata


## Devuelve el valor de una variable de contexto, o default si no existe.
func get_variable(key: String, default_value: Variant = null) -> Variant:
	return variables.get(key, default_value)


## Devuelve el valor de una referencia de contexto, o default si no existe.
func get_reference(key: String, default_value: Variant = null) -> Variant:
	return references.get(key, default_value)


## Devuelve una copia de este contexto como un Dictionary de solo lectura.
func to_dictionary() -> Dictionary:
	return {
		"cinematic_id": cinematic_id,
		"requester_id": requester_id,
		"origin_id": origin_id,
		"variables": variables,
		"references": references,
		"allow_skip": allow_skip,
		"timestamp": timestamp,
		"metadata": metadata,
	}
