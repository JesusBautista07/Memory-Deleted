class_name CinematicCamera
extends RefCounted
## Estructura de configuración de una cámara cinematográfica.
##
## Almacena únicamente los datos de configuración que, en el futuro, un
## sistema externo podría usar para posicionar o mezclar una cámara.
## No mueve ninguna cámara, no interpola valores y no controla ningún
## Viewport ni nodo de escena.

## Tipos de transición soportados por la estructura (solo descriptivos).
enum TransitionType {
	CUT,
	LINEAR,
	EASE_IN,
	EASE_OUT,
	EASE_IN_OUT,
}

## Identificador de la configuración de cámara (útil para debug o referencias).
var camera_id: StringName = &""

## Nombre legible de la configuración (para editor, debug o UI).
var display_name: String = ""

## Posición deseada de la cámara en el espacio.
var position: Vector3 = Vector3.ZERO

## Rotación deseada de la cámara, en radianes (Euler).
var rotation: Vector3 = Vector3.ZERO

## Campo de visión (field of view) deseado, en grados.
var fov: float = 70.0

## Distancia del plano de recorte cercano.
var near_clip: float = 0.05

## Distancia del plano de recorte lejano.
var far_clip: float = 4000.0

## Identificador libre de un objetivo a seguir/enfocar (sin referenciar
## ningún nodo concreto; el sistema externo decide cómo resolverlo).
var target_id: StringName = &""

## Desplazamiento (offset) respecto al objetivo, si aplica.
var target_offset: Vector3 = Vector3.ZERO

## Tipo de transición deseado al entrar en uso esta configuración.
var transition_type: int = TransitionType.CUT

## Duración deseada de la transición, en segundos.
var transition_duration: float = 0.0

## Prioridad relativa de esta configuración de cámara (uso libre).
var priority: int = 0

## Datos adicionales de propósito genérico, para extensión futura.
var metadata: Dictionary = {}


func _init(
	p_camera_id: StringName = &"",
	p_display_name: String = "",
	p_position: Vector3 = Vector3.ZERO,
	p_rotation: Vector3 = Vector3.ZERO,
	p_fov: float = 70.0,
	p_target_id: StringName = &"",
	p_transition_type: int = TransitionType.CUT,
	p_transition_duration: float = 0.0,
	p_metadata: Dictionary = {}
) -> void:
	camera_id = p_camera_id
	display_name = p_display_name
	position = p_position
	rotation = p_rotation
	fov = p_fov
	target_id = p_target_id
	transition_type = p_transition_type
	transition_duration = p_transition_duration
	metadata = p_metadata


## Devuelve una copia de esta configuración como un Dictionary de solo lectura.
func to_dictionary() -> Dictionary:
	return {
		"camera_id": camera_id,
		"display_name": display_name,
		"position": position,
		"rotation": rotation,
		"fov": fov,
		"near_clip": near_clip,
		"far_clip": far_clip,
		"target_id": target_id,
		"target_offset": target_offset,
		"transition_type": transition_type,
		"transition_duration": transition_duration,
		"priority": priority,
		"metadata": metadata,
	}
