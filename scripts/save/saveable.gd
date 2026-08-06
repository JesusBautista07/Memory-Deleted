class_name Saveable
extends Node

## Interfaz base opcional para cualquier sistema que quiera exponer su
## propio estado guardable, sin que ese sistema ni el guardado se conozcan
## entre sí de forma directa.
##
## No depende de Player, Inventario, Documentos, Puertas, Eventos,
## Puzzles, Audio, Ambientación, UI ni Escenarios. No depende de ningún
## SaveManager concreto.
##
## Un sistema puede heredar de esta clase e implementar sus propios
## get_save_data() / load_save_data(), o bien limitarse a exponer esos
## mismos métodos por duck typing sin heredar de aquí. Ambas formas son
## válidas: Saveable es una interfaz, no un requisito obligatorio.

## Identificador estable de esta instancia guardable.
## Permite emparejar datos guardados con la instancia correcta al
## recargar una escena, incluso si el orden de los nodos cambia.
## Vacío por defecto: quien herede decide si lo necesita.
var save_id: String = ""


## Método virtual. Debe devolver el estado actual de este sistema como
## datos genéricos (Dictionary, Array, String, bool, float, int),
## listos para ser serializados. La implementación base no sabe nada
## de quién la llama ni de cómo se persistirá el resultado.
func get_save_data() -> Dictionary:
	return {}


## Método virtual. Recibe los datos previamente devueltos por
## get_save_data() (ya deserializados) y restaura el estado de este
## sistema a partir de ellos. La implementación base no hace nada.
func load_save_data(data: Dictionary) -> void:
	pass
