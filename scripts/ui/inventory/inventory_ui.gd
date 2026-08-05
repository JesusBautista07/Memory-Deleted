extends Control
class_name InventoryUI

signal closed
signal document_item_added(item: InventoryItem)

const INVENTORY_MANAGER_GROUP := "inventory_manager"

@export var inventory_manager_path: NodePath

@onready var _category_tabs: TabBar = %CategoryTabs
@onready var _item_list: ItemList = %ItemList
@onready var _item_name_label: Label = %ItemNameLabel
@onready var _item_description_label: Label = %ItemDescriptionLabel
@onready var _button_close: Button = %ButtonClose

var _inventory_manager: InventoryManager = null
var _list_ids: Array[String] = []

func _ready() -> void:
	_button_close.pressed.connect(_on_button_close_pressed)
	_item_list.item_selected.connect(_on_item_list_item_selected)
	_resolve_inventory_manager()

func _resolve_inventory_manager() -> void:
	if not inventory_manager_path.is_empty():
		var node: Node = get_node_or_null(inventory_manager_path)
		if node is InventoryManager:
			_bind_inventory_manager(node)
			return

	var found: Node = get_tree().get_first_node_in_group(INVENTORY_MANAGER_GROUP)
	if found is InventoryManager:
		_bind_inventory_manager(found)

func set_inventory_manager(manager: InventoryManager) -> void:
	_bind_inventory_manager(manager)

func _bind_inventory_manager(manager: InventoryManager) -> void:
	_inventory_manager = manager
	_inventory_manager.item_added.connect(_on_item_added)
	_inventory_manager.item_removed.connect(_on_item_removed)
	_inventory_manager.inventory_cleared.connect(_on_inventory_cleared)
	refresh()

func refresh() -> void:
	_item_list.clear()
	_list_ids.clear()
	_clear_details()

	if _inventory_manager == null:
		return

	for item in _inventory_manager.get_all_items():
		_add_item_to_list(item)

func _add_item_to_list(item: InventoryItem) -> void:
	var label: String = item.nombre
	if item.apilable and item.cantidad > 1:
		label += " x%d" % item.cantidad

	_item_list.add_item(label)
	_list_ids.append(item.id)

	if item.es_documento():
		document_item_added.emit(item)

func _on_item_added(_item: InventoryItem) -> void:
	refresh()

func _on_item_removed(_item: InventoryItem) -> void:
	refresh()

func _on_inventory_cleared() -> void:
	refresh()

func _on_item_list_item_selected(index: int) -> void:
	if index < 0 or index >= _list_ids.size():
		return

	var item: InventoryItem = _inventory_manager.find_item(_list_ids[index])
	if item == null:
		return

	_item_name_label.text = item.nombre
	_item_description_label.text = item.descripcion

func _clear_details() -> void:
	_item_name_label.text = ""
	_item_description_label.text = ""

func _on_button_close_pressed() -> void:
	closed.emit()

func request_open_document(_object_id: String) -> void:
	pass
