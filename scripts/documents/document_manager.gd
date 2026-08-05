extends Node
class_name DocumentManager

signal document_opened(document_data: DocumentData)
signal document_closed(document_data: DocumentData)
signal page_changed(document_data: DocumentData, page_index: int)
signal document_marked_read(document_data: DocumentData)

const GROUP_NAME := "document_manager"
const INVENTORY_GROUP := "inventory"
const EVENT_MANAGER_GROUP := "event_manager"

@export var documents: Array[DocumentData] = []

var _documents_by_id: Dictionary = {}
var _current_document: DocumentData = null
var _current_page: int = 0

func _ready() -> void:
	add_to_group(GROUP_NAME)
	_index_documents()
	_connect_inventory()

func _index_documents() -> void:
	for doc in documents:
		if doc != null and not doc.document_id.is_empty():
			_documents_by_id[doc.document_id] = doc

func register_document(document_data: DocumentData) -> void:
	if document_data == null or document_data.document_id.is_empty():
		return
	_documents_by_id[document_data.document_id] = document_data

func has_document(document_id: String) -> bool:
	return _documents_by_id.has(document_id)

func get_document(document_id: String) -> DocumentData:
	return _documents_by_id.get(document_id)

func open_document(document_id: String) -> bool:
	if not _documents_by_id.has(document_id):
		return false

	_current_document = _documents_by_id[document_id]
	_current_page = 0
	document_opened.emit(_current_document)
	page_changed.emit(_current_document, _current_page)
	_mark_as_read(_current_document)
	return true

func close_document() -> void:
	if _current_document == null:
		return

	var closed_document: DocumentData = _current_document
	_current_document = null
	_current_page = 0
	document_closed.emit(closed_document)

func next_page() -> void:
	if _current_document == null:
		return
	if _current_page + 1 >= _current_document.get_page_count():
		return
	_current_page += 1
	page_changed.emit(_current_document, _current_page)

func previous_page() -> void:
	if _current_document == null:
		return
	if _current_page - 1 < 0:
		return
	_current_page -= 1
	page_changed.emit(_current_document, _current_page)

func get_current_document() -> DocumentData:
	return _current_document

func get_current_page_index() -> int:
	return _current_page

func get_current_page_text() -> String:
	if _current_document == null:
		return ""
	return _current_document.get_page_text(_current_page)

func get_current_page_image() -> Texture2D:
	if _current_document == null:
		return null
	return _current_document.get_page_image(_current_page)

func get_save_data() -> Dictionary:
	var data: Dictionary = {}
	for document_id in _documents_by_id.keys():
		var doc: DocumentData = _documents_by_id[document_id]
		data[document_id] = {
			"is_read": doc.is_read,
			"date_obtained": doc.date_obtained,
			"last_page": _current_page if doc == _current_document else 0,
		}
	return data

func load_save_data(data: Dictionary) -> void:
	for document_id in data.keys():
		if not _documents_by_id.has(document_id):
			continue
		var doc: DocumentData = _documents_by_id[document_id]
		var entry: Dictionary = data[document_id]
		doc.is_read = entry.get("is_read", false)
		doc.date_obtained = entry.get("date_obtained", "")

func _connect_inventory() -> void:
	var inventory: Node = get_tree().get_first_node_in_group(INVENTORY_GROUP)
	if inventory == null:
		return
	if inventory.has_signal("document_registered"):
		inventory.document_registered.connect(_on_document_registered_in_inventory)

func _on_document_registered_in_inventory(object_data: ObjectData, _source: Node) -> void:
	if object_data == null:
		return
	if _documents_by_id.has(object_data.object_id):
		return

	var doc := DocumentData.new()
	doc.document_id = object_data.object_id
	doc.title = object_data.object_name
	doc.note = object_data.description
	register_document(doc)

func _mark_as_read(document_data: DocumentData) -> void:
	if document_data.is_read:
		return
	document_data.is_read = true
	document_marked_read.emit(document_data)
	_notify_event_manager(document_data)

func _notify_event_manager(document_data: DocumentData) -> void:
	var event_manager: Node = get_tree().get_first_node_in_group(EVENT_MANAGER_GROUP)
	if event_manager == null or not event_manager.has_method("trigger_event"):
		return
	event_manager.call("trigger_event", "document_read_%s" % document_data.document_id, {"document": document_data})
