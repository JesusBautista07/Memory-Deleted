extends Node
class_name Inventory

signal item_added(object_data: ObjectData)
signal item_removed(object_data: ObjectData)
signal document_registered(object_data: ObjectData, source: PickupObject)
signal inventory_changed(items: Array)

const GROUP_NAME := "inventory"

var _items: Array[ObjectData] = []
var _document_ids: Array[String] = []

func _ready() -> void:
	add_to_group(GROUP_NAME)

func add_item(object_data: ObjectData, source: PickupObject = null) -> bool:
	if object_data == null:
		return false

	if not object_data.can_be_stored:
		return false

	if has_item(object_data.object_id):
		return false

	_items.append(object_data)
	item_added.emit(object_data)
	inventory_changed.emit(get_items())

	if source is DocumentItem:
		_register_document(object_data, source)

	return true

func remove_item(object_id: String) -> bool:
	for i in range(_items.size()):
		if _items[i].object_id == object_id:
			var removed: ObjectData = _items[i]
			_items.remove_at(i)
			item_removed.emit(removed)
			inventory_changed.emit(get_items())
			return true
	return false

func has_item(object_id: String) -> bool:
	for data in _items:
		if data.object_id == object_id:
			return true
	return false

func get_items() -> Array[ObjectData]:
	return _items.duplicate()

func get_item(object_id: String) -> ObjectData:
	for data in _items:
		if data.object_id == object_id:
			return data
	return null

func is_document(object_id: String) -> bool:
	return _document_ids.has(object_id)

func get_document_ids() -> Array[String]:
	return _document_ids.duplicate()

func _register_document(object_data: ObjectData, source: PickupObject) -> void:
	if _document_ids.has(object_data.object_id):
		return
	_document_ids.append(object_data.object_id)
	document_registered.emit(object_data, source)
