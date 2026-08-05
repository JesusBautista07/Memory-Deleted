extends PickupObject
class_name DocumentItem

signal read_requested(document_id: String, document_text: String)

@export_multiline var document_text: String = ""
@export var document_texture: Texture2D
@export var read_on_pickup: bool = false

func interact() -> void:
	super.interact()
	if read_on_pickup:
		request_read()

func request_read() -> void:
	read_requested.emit(get_object_id(), document_text)

func get_document_text() -> String:
	return document_text
