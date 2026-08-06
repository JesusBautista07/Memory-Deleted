class_name CinematicTrigger
extends RefCounted
## Estructura de un disparador (trigger) de cinemática.
##
## Almacena únicamente los datos necesarios para que, en el futuro, un
## sistema externo pueda decidir activar una cinemática (qué cinemática,
## bajo qué tipo de disparo y con qué condiciones). No detecta colisiones,
## no escucha señales de área y no ejecuta ninguna cinemática.

## Tipos de disparo soportados por la estructura del trigger.
enum TriggerType {
	AREA,
	INTERACTION,
	SCRIPTED,
	EVENT,
	CUTSCENE_CHAIN,
}

## Identificador del trigger (útil para debug, referencias o desuplicado).
var trigger_id: StringName = &""

## Identificador de la cinemática (CinematicData) que este trigger
## activaría. Referencia libre, sin depender de ningún Registry.
var cinematic_id: StringName = &""

## Tipo de disparo que representa este trigger (ver enum TriggerType).
var trigger_type: int = TriggerType.SCRIPTED

## Indica si el trigger está habilitado.
var is_enabled: bool = true

## Indica si el trigger debería activarse una única vez.
var is_one_shot: bool = false

## Indica si, según la información disponible, el trigger ya fue activado.
var has_triggered: bool = false

## Prioridad relativa del trigger (uso libre para quien lo consuma).
var priority: int = 0

## Condiciones declaradas que deberían cumplirse para activar el trigger.
var _conditions: Array[CinematicCondition] = []

## Datos de contexto libres a aportar al activarse el trigger (clave -> valor).
var context_data: Dictionary = {}

## Datos adicionales de propósito genérico, para extensión futura.
var metadata: Dictionary = {}


func _init(
	p_trigger_id: StringName = &"",
	p_cinematic_id: StringName = &"",
	p_trigger_type: int = TriggerType.SCRIPTED,
	p_is_enabled: bool = true,
	p_is_one_shot: bool = false,
	p_priority: int = 0,
	p_context_data: Dictionary = {},
	p_metadata: Dictionary = {}
) -> void:
	trigger_id = p_trigger_id
	cinematic_id = p_cinematic_id
	trigger_type = p_trigger_type
	is_enabled = p_is_enabled
	is_one_shot = p_is_one_shot
	priority = p_priority
	context_data = p_context_data
	metadata = p_metadata


## Añade una condición requerida por este trigger. Devuelve false si es nula.
func add_condition(condition: CinematicCondition) -> bool:
	if condition == null:
		return false

	_conditions.append(condition)
	return true


## Elimina la primera condición encontrada con el condition_id dado.
func remove_condition(condition_id: StringName) -> bool:
	for i in _conditions.size():
		if _conditions[i].condition_id == condition_id:
			_conditions.remove_at(i)
			return true
	return false


## Devuelve todas las condiciones declaradas para este trigger.
func get_conditions() -> Array[CinematicCondition]:
	return _conditions.duplicate()


## Devuelve una copia de este trigger como un Dictionary de solo lectura.
func to_dictionary() -> Dictionary:
	return {
		"trigger_id": trigger_id,
		"cinematic_id": cinematic_id,
		"trigger_type": trigger_type,
		"is_enabled": is_enabled,
		"is_one_shot": is_one_shot,
		"has_triggered": has_triggered,
		"priority": priority,
		"context_data": context_data,
		"metadata": metadata,
	}
