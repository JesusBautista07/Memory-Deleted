extends Control
class_name InventoryUI

signal closed
signal document_item_added(item: ObjectData)

const INVENTORY_GROUP := "inventory"

@export var inventory_path: NodePath

@onready var _category_tabs: TabBar = %CategoryTabs
@onready var _item_list: ItemList = %ItemList
@onready var _item_name_label: Label = %ItemNameLabel
@onready var _item_description_label: Label = %ItemDescriptionLabel
@onready var _button_close: Button = %ButtonClose

var _inventory: Inventory = null
var _list_ids: Array[String] = []

func _ready() -> void:
	_button_close.pressed.connect(_on_button_close_pressed)
	_item_list.item_selected.connect(_on_item_list_item_selected)
	_resolve_inventory()

func _resolve_inventory() -> void:
	if not inventory_path.is_empty():
		var node: Node = get_node_or_null(inventory_path)
		if node is Inventory:
			_bind_inventory(node)
			return

	var found: Node = get_tree().get_first_node_in_group(INVENTORY_GROUP)
	if found is Inventory:
		_bind_inventory(found)

func set_inventory(inventory: Inventory) -> void:
	_bind_inventory(inventory)

func _bind_inventory(inventory: Inventory) -> void:
	_inventory = inventory
	_inventory.item_added.connect(_on_item_added)
	_inventory.item_removed.connect(_on_item_removed)
	refresh()

func refresh() -> void:
	_item_list.clear()
	_list_ids.clear()
	_clear_details()

	if _inventory == null:
		return

	for item in _inventory.get_items():
		_add_item_to_list(item)

func _add_item_to_list(item: ObjectData) -> void:
	_item_list.add_item(item.object_name)
	_list_ids.append(item.object_id)

	if _inventory.is_document(item.object_id):
		document_item_added.emit(item)

func _on_item_added(_item: ObjectData) -> void:
	refresh()

func _on_item_removed(_item: ObjectData) -> void:
	refresh()

func _on_item_list_item_selected(index: int) -> void:
	if index < 0 or index >= _list_ids.size():
		return

	var item: ObjectData = _inventory.get_item(_list_ids[index])
	if item == null:
		return

	_item_name_label.text = item.object_name
	_item_description_label.text = item.description

func _clear_details() -> void:
	_item_name_label.text = ""
	_item_description_label.text = ""

func _on_button_close_pressed() -> void:
	closed.emit()

func request_open_document(_object_id: String) -> void:
	pass
