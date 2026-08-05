extends Node3D
class_name InteractionManager

signal target_found(target: Object)
signal target_lost(target: Object)
signal interacted(target: Object)

@export var ray_cast: RayCast3D
@export var interact_action: String = "interact"

var _current_target: Object = null

func _ready() -> void:
	if ray_cast:
		ray_cast.enabled = true

func _physics_process(_delta: float) -> void:
	_update_target()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(interact_action):
		_try_interact()

func _update_target() -> void:
	var detected: Object = _get_interactable()

	if detected != _current_target:
		if _current_target != null:
			_on_target_lost()
		if detected != null:
			_on_target_found(detected)
		_current_target = detected

func _get_interactable() -> Object:
	if ray_cast == null or not ray_cast.is_colliding():
		return null

	var collider: Object = ray_cast.get_collider()

	if collider == null:
		return null

	if not collider.has_method("interact"):
		return null

	return collider

func _on_target_found(target: Object) -> void:
	show_interaction()
	target_found.emit(target)

func _on_target_lost() -> void:
	var target: Object = _current_target
	hide_interaction()
	target_lost.emit(target)

func _try_interact() -> void:
	if _current_target != null and _current_target.has_method("interact"):
		_current_target.call("interact")
		interacted.emit(_current_target)

func show_interaction() -> void:
	pass

func hide_interaction() -> void:
	pass

func get_current_target() -> Object:
	return _current_target
