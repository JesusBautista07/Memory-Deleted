extends Control
## Interfaz de inventario (sin lógica de inventario real).
## Se alimenta desde fuera mediante populate_category(); acepta
## Dictionary o cualquier Object con propiedades "nombre"/"descripcion"
## (compatible con InventoryItem sin depender de esa clase).

signal closed

enum Category { ITEMS, KEY_ITEMS, DOCUMENTS }

@onready var _tab_bar: TabBar = %CategoryTabs
@onready var _item_list: ItemList = %ItemList
@onready var _item_name_label: Label = %ItemNameLabel
@onready var _item_description_label: Label = %ItemDescriptionLabel
@onready var _button_close: Button = %ButtonClose

var _current_category: int = Category.ITEMS
var _items_by_category: Dictionary = {
	Category.ITEMS: [],
	Category.KEY_ITEMS: [],
	Category.DOCUMENTS: [],
}


func _ready() -> void:
	_tab_bar.add_tab("Objetos")
	_tab_bar.add_tab("Objetos Clave")
	_tab_bar.add_tab("Documentos")
	_tab_bar.current_tab = 0

	_tab_bar.tab_changed.connect(_on_tab_changed)
	_item_list.item_selected.connect(_on_item_selected)
	_button_close.pressed.connect(_on_close_pressed)

	_refresh_list()
	_clear_details()


func populate_category(category: int, items: Array) -> void:
	_items_by_category[category] = items
	if category == _current_category:
		_refresh_list()


func clear_all() -> void:
	for category in _items_by_category.keys():
		_items_by_category[category] = []
	_refresh_list()
	_clear_details()


func _on_tab_changed(tab_index: int) -> void:
	_current_category = tab_index
	_refresh_list()
	_clear_details()


func _on_item_selected(index: int) -> void:
	var items: Array = _items_by_category[_current_category]
	if index < 0 or index >= items.size():
		return
	_show_details(items[index])


func _refresh_list() -> void:
	_item_list.clear()
	for item in _items_by_category[_current_category]:
		_item_list.add_item(_get_item_field(item, "nombre"))


func _show_details(item) -> void:
	_item_name_label.text = _get_item_field(item, "nombre")
	_item_description_label.text = _get_item_field(item, "descripcion")


func _get_item_field(item, field_name: String) -> String:
	if item is Dictionary and item.has(field_name):
		return String(item[field_name])
	if item is Object:
		var value = item.get(field_name)
		if value != null:
			return String(value)
	return ""


func _clear_details() -> void:
	_item_name_label.text = ""
	_item_description_label.text = ""


func _on_close_pressed() -> void:
	closed.emit()
