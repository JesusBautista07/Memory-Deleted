class_name CinematicCondition
extends RefCounted
## Estructura de una condición asociada a una cinemática.
##
## Únicamente define la forma de una condición (qué se compara, contra
## qué valor y con qué operador). No evalúa nada: la evaluación es
## responsabilidad de un sistema externo ajeno a este módulo.

## Tipos de comparación soportados por la estructura de la condición.
enum Comparison {
	EQUAL,
	NOT_EQUAL,
	GREATER,
	GREATER_OR_EQUAL,
	LESS,
	LESS_OR_EQUAL,
	HAS_FLAG,
	NOT_HAS_FLAG,
}

## Identificador de la condición (útil para debug o referencias externas).
var condition_id: StringName = &""

## Clave del dato a comparar (ej: nombre de una variable, flag o estadística).
## Se define de forma libre para no acoplarse a ningún sistema concreto.
var target_key: StringName = &""

## Valor esperado contra el cual se comparará target_key.
var expected_value: Variant = null

## Operador de comparación a utilizar (ver enum Comparison).
var comparison: int = Comparison.EQUAL

## Si es true, el resultado de la evaluación deberá invertirse (NOT lógico).
var negate: bool = false

## Descripción libre de la condición, útil para debug/editor.
var description: String = ""

## Datos adicionales de propósito genérico, para extensión futura.
var metadata: Dictionary = {}


func _init(
	p_condition_id: StringName = &"",
	p_target_key: StringName = &"",
	p_expected_value: Variant = null,
	p_comparison: int = Comparison.EQUAL,
	p_negate: bool = false,
	p_description: String = "",
	p_metadata: Dictionary = {}
) -> void:
	condition_id = p_condition_id
	target_key = p_target_key
	expected_value = p_expected_value
	comparison = p_comparison
	negate = p_negate
	description = p_description
	metadata = p_metadata


## Devuelve una copia de esta condición como un Dictionary de solo lectura.
func to_dictionary() -> Dictionary:
	return {
		"condition_id": condition_id,
		"target_key": target_key,
		"expected_value": expected_value,
		"comparison": comparison,
		"negate": negate,
		"description": description,
		"metadata": metadata,
	}
