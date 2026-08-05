extends Interactable
class_name PickupObject

signal picked_up(object_data: ObjectData, source: PickupObject)
signal storage_rejected(object_data: ObjectData, source: PickupObject)

@export var object_data: ObjectData
@export var disable_on_pickup: bool = true
@export var visual_root: Node3D

var _picked_up: bool = false

func interact() -> void:
	if not can_interact or _picked_up:
		return

	if object_data == null:
		return

	if not object_data.can_be_stored:
		storage_rejected.emit(object_data, self)
		return

	_picked_up = true
	picked_up.emit(object_data, self)
	super.interact()

	if disable_on_pickup:
		deactivate()

func deactivate() -> void:
	set_interactable(false)
	if visual_root != null:
		visual_root.visible = false
	else:
		visible = false

func is_picked_up() -> bool:
	return _picked_up

func get_object_data() -> ObjectData:
	return object_data

func get_object_id() -> String:
	if object_data == null:
		return ""
	return object_data.object_id

func is_key_item() -> bool:
	if object_data == null:
		return false
	return object_data.is_key_item
