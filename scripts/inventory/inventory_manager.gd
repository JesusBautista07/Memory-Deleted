extends Node
class_name InventoryManager
## Lógica base del sistema de inventario.
## Sin dependencias de UI, jugador, interacción, puertas ni documentos.
## Preparado para integrarse posteriormente con el sistema de interacción.

signal item_added(item: InventoryItem)
signal item_removed(item: InventoryItem)
signal item_used(item: InventoryItem)
signal selection_changed(item: InventoryItem)
signal inventory_cleared()

var _items: Dictionary = {}  # id: String -> InventoryItem
var _selected_id: String = ""


func add_item(item: InventoryItem) -> bool:
	if item == null or item.id.is_empty():
		return false

	if item.apilable and _items.has(item.id):
		_items[item.id].cantidad += item.cantidad
	else:
		_items[item.id] = item

	item_added.emit(_items[item.id])
	return true


func remove_item(id: String, cantidad: int = 1) -> bool:
	if not has_item(id):
		return false

	var item: InventoryItem = _items[id]

	if item.apilable and item.cantidad > cantidad:
		item.cantidad -= cantidad
	else:
		_items.erase(id)
		if _selected_id == id:
			_set_selected(null)

	item_removed.emit(item)
	return true


func find_item(id: String) -> InventoryItem:
	return _items.get(id, null)


func has_item(id: String) -> bool:
	return _items.has(id)


func get_all_items() -> Array[InventoryItem]:
	var lista: Array[InventoryItem] = []
	for item in _items.values():
		lista.append(item)
	return lista


func select_item(id: String) -> bool:
	if not has_item(id):
		return false

	_set_selected(_items[id])
	return true


func get_selected_item() -> InventoryItem:
	return find_item(_selected_id)


func use_item(id: String) -> bool:
	if not has_item(id):
		return false

	var item: InventoryItem = _items[id]
	item_used.emit(item)

	if item.apilable:
		remove_item(id, 1)

	return true


func clear_inventory() -> void:
	_items.clear()
	_set_selected(null)
	inventory_cleared.emit()


func _set_selected(item: InventoryItem) -> void:
	_selected_id = item.id if item != null else ""
	selection_changed.emit(item)
