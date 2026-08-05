extends PickupObject
class_name WatchItem

signal time_check_requested(watch_id: String)

func request_time_check() -> void:
	time_check_requested.emit(get_object_id())
