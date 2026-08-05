extends PickupObject
class_name KeyItem

signal key_used(key_id: String, target: Object)

@export var unlocks_id: String = ""

func use_on(target: Object) -> void:
	if not _picked_up:
		return
	key_used.emit(get_object_id(), target)

func get_unlocks_id() -> String:
	return unlocks_id
