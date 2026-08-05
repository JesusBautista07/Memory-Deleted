extends Control
class_name InventoryUI

const INVENTORY_GROUP := "inventory"

@export var slot_container: Control
@export var slot_scene: PackedScene

var _inventory: Inventory = null
var _slots_by_id: Dictionary = {}

func _ready() -> void:
	_resolve_inventory()

func _resolve_inventory() -> void:
	var node: Node = get_tree().get_first_node_in_group(INVENTORY_GROUP)
	if node is Inventory:
		_bind_inventory(node)

func _bind_inventory(inventory: Inventory) -> void:
	_inventory = inventory
	_inventory.item_added.connect(_on_item_added)
	_inventory.item_removed.connect(_on_item_removed)
	_inventory.document_registered.connect(_on_document_registered)
	refresh()

func refresh() -> void:
	if _inventory == null:
		return
	for object_data in _inventory.get_items():
		_ensure_slot(object_data)

func _on_item_added(object_data: ObjectData) -> void:
	_ensure_slot(object_data)

func _on_item_removed(object_data: ObjectData) -> void:
	_remove_slot(object_data)

func _on_document_registered(object_data: ObjectData, _source: PickupObject) -> void:
	_mark_slot_as_document(object_data)

func _ensure_slot(object_data: ObjectData) -> void:
	if object_data == null or _slots_by_id.has(object_data.object_id):
		return
	_slots_by_id[object_data.object_id] = object_data
	_on_slot_created(object_data)

func _remove_slot(object_data: ObjectData) -> void:
	if object_data == null:
		return
	_slots_by_id.erase(object_data.object_id)
	_on_slot_removed(object_data)

func _mark_slot_as_document(object_data: ObjectData) -> void:
	_on_slot_marked_as_document(object_data)

func _on_slot_created(_object_data: ObjectData) -> void:
	pass

func _on_slot_removed(_object_data: ObjectData) -> void:
	pass

func _on_slot_marked_as_document(_object_data: ObjectData) -> void:
	pass

func request_open_document(_object_id: String) -> void:
	pass
