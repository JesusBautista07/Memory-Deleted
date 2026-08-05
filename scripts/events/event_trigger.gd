extends Area3D
class_name EventTrigger
## Zona (Area3D) que avisa al EventManager al detectar un cuerpo dentro.
## No contiene lógica de historia: solo reenvía los ids de evento
## configurados. La identidad del cuerpo (p. ej. el Player) se filtra
## mediante grupo, sin depender directamente de ninguna clase concreta.

@export var event_ids: Array[String] = []
@export var required_group: String = "player"  # vacío = acepta cualquier cuerpo
@export var trigger_once: bool = true

var _has_triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if trigger_once and _has_triggered:
		return

	if not required_group.is_empty() and not body.is_in_group(required_group):
		return

	_has_triggered = true
	_fire_events()


func _fire_events() -> void:
	var manager: Node = get_tree().get_first_node_in_group(EventManager.GROUP_NAME)
	if manager == null:
		push_warning("EventTrigger: no se encontró ningún EventManager en el grupo '%s'." % EventManager.GROUP_NAME)
		return

	manager.trigger_events(event_ids)


func reset_trigger() -> void:
	_has_triggered = false
