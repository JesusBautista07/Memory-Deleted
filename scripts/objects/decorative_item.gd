extends Interactable
class_name DecorativeItem

signal examined(object_data: ObjectData, source: DecorativeItem)

@export var object_data: ObjectData

func interact() -> void:
	if not can_interact:
		return
	examined.emit(object_data, self)
	super.interact()

func get_object_data() -> ObjectData:
	return object_data
