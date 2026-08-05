extends PickupObject
class_name PhoneItem

signal screen_requested(phone_id: String)

@export var has_new_message: bool = false

func request_screen() -> void:
	screen_requested.emit(get_object_id())

func set_has_new_message(value: bool) -> void:
	has_new_message = value
