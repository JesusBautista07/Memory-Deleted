extends Area3D
class_name EventTrigger

signal triggered(event_id: String)

@export var event_id: String = ""
@export var event_category: EventManager.EventCategory = EventManager.EventCategory.NONE
@export var trigger_once: bool = true
@export var trigger_on_enter: bool = true
@export var event_manager_path: NodePath

var _event_manager: EventManager = null
var _has_triggered: bool = false

func _ready() -> void:
	_resolve_event_manager()

	if trigger_on_enter:
		body_entered.connect(_on_body_entered)
	else:
		body_exited.connect(_on_body_exited)

func _resolve_event_manager() -> void:
	if event_manager_path.is_empty():
		return

	var node: Node = get_node_or_null(event_manager_path)
	if node is EventManager:
		_event_manager = node

func set_event_manager(manager: EventManager) -> void:
	_event_manager = manager

func _on_body_entered(_body: Node3D) -> void:
	_fire()

func _on_body_exited(_body: Node3D) -> void:
	_fire()

func _fire() -> void:
	if event_id.is_empty():
		return

	if trigger_once and _has_triggered:
		return

	_has_triggered = true
	triggered.emit(event_id)

	if _event_manager != null:
		_event_manager.trigger_event(event_id, {"category": event_category})

func reset_trigger() -> void:
	_has_triggered = false
