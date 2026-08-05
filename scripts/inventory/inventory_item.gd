extends Resource
class_name InventoryItem
## Estructura de datos de un objeto de inventario.
## No contiene lógica de UI, jugador, interacción, puertas ni documentos.

enum ItemType {
	NORMAL,
	KEY_ITEM,
	DOCUMENT,
}

@export var id: String = ""
@export var nombre: String = ""
@export var descripcion: String = ""
@export var tipo: ItemType = ItemType.NORMAL
@export var cantidad: int = 1
@export var apilable: bool = false
@export var objeto_clave: bool = false


func es_documento() -> bool:
	return tipo == ItemType.DOCUMENT


func es_objeto_clave() -> bool:
	return objeto_clave or tipo == ItemType.KEY_ITEM


func duplicar() -> InventoryItem:
	var copia := InventoryItem.new()
	copia.id = id
	copia.nombre = nombre
	copia.descripcion = descripcion
	copia.tipo = tipo
	copia.cantidad = cantidad
	copia.apilable = apilable
	copia.objeto_clave = objeto_clave
	return copia
