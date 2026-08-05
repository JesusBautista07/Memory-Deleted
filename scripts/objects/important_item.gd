extends PickupObject
class_name ImportantItem

signal event_requested(event_id: String, source: ImportantItem)
signal puzzle_unlock_requested(puzzle_id: String, source: ImportantItem)
signal dialogue_requested(dialogue_id: String, source: ImportantItem)

const EVENT_MANAGER_GROUP := "event_manager"

@export var linked_event_id: String = ""
@export var linked_puzzle_id: String = ""
@export var linked_dialogue_id: String = ""
@export var trigger_on_pickup: bool = true

func interact() -> void:
	super.interact()
	if trigger_on_pickup:
		trigger_links()

func trigger_links() -> void:
	if not linked_event_id.is_empty():
		event_requested.emit(linked_event_id, self)
		_forward_event_to_manager(linked_event_id)
	if not linked_puzzle_id.is_empty():
		puzzle_unlock_requested.emit(linked_puzzle_id, self)
	if not linked_dialogue_id.is_empty():
		dialogue_requested.emit(linked_dialogue_id, self)

func _forward_event_to_manager(event_id: String) -> void:
	var event_manager: Node = get_tree().get_first_node_in_group(EVENT_MANAGER_GROUP)
	if event_manager == null or not event_manager.has_method("trigger_event"):
		return
	event_manager.call("trigger_event", event_id, {"source": self})
