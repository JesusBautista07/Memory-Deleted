extends PickupObject
class_name ImportantItem

signal event_requested(event_id: String, source: ImportantItem)
signal puzzle_unlock_requested(puzzle_id: String, source: ImportantItem)
signal dialogue_requested(dialogue_id: String, source: ImportantItem)

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
	if not linked_puzzle_id.is_empty():
		puzzle_unlock_requested.emit(linked_puzzle_id, self)
	if not linked_dialogue_id.is_empty():
		dialogue_requested.emit(linked_dialogue_id, self)
