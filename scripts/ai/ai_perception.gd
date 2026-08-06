class_name AIPerception
extends Node

signal target_seen(target: Node)
signal target_lost(target: Node)
signal sound_heard(origin: Vector3, intensity: float)
signal zone_entered(zone: Node)
signal zone_exited(zone: Node)
signal object_detected(object: Node)
signal ally_detected(ally: Node)
signal enemy_detected(enemy: Node)

@export var vision_range: float = 10.0
@export var vision_angle_degrees: float = 90.0
@export var hearing_range: float = 15.0

@export var vision_group: String = ""
@export var hearing_group: String = ""
@export var zone_group: String = ""
@export var object_group: String = ""
@export var ally_group: String = ""
@export var enemy_group: String = ""

var origin_node: Node3D


func setup(p_origin_node: Node3D) -> void:
	origin_node = p_origin_node


func get_distance_to(target: Node3D) -> float:
	if origin_node == null or target == null:
		return INF
	return origin_node.global_position.distance_to(target.global_position)


func is_within_vision_range(target: Node3D) -> bool:
	return get_distance_to(target) <= vision_range


func is_within_hearing_range(origin: Vector3) -> bool:
	if origin_node == null:
		return false
	return origin_node.global_position.distance_to(origin) <= hearing_range


func is_within_vision_angle(target: Node3D) -> bool:
	if origin_node == null or target == null:
		return false
	var to_target: Vector3 = (target.global_position - origin_node.global_position).normalized()
	var forward: Vector3 = -origin_node.global_transform.basis.z
	var angle: float = rad_to_deg(forward.angle_to(to_target))
	return angle <= vision_angle_degrees * 0.5


func get_nodes_in_group(group_name: String) -> Array[Node]:
	if group_name.is_empty():
		return []
	return get_tree().get_nodes_in_group(group_name)


func scan_vision_targets() -> Array[Node]:
	return get_nodes_in_group(vision_group)


func scan_objects() -> Array[Node]:
	return get_nodes_in_group(object_group)


func scan_allies() -> Array[Node]:
	return get_nodes_in_group(ally_group)


func scan_enemies() -> Array[Node]:
	return get_nodes_in_group(enemy_group)


func scan_zones() -> Array[Node]:
	return get_nodes_in_group(zone_group)


func report_target_seen(target: Node) -> void:
	target_seen.emit(target)


func report_target_lost(target: Node) -> void:
	target_lost.emit(target)


func report_sound_heard(origin: Vector3, intensity: float) -> void:
	sound_heard.emit(origin, intensity)


func report_zone_entered(zone: Node) -> void:
	zone_entered.emit(zone)


func report_zone_exited(zone: Node) -> void:
	zone_exited.emit(zone)


func report_object_detected(object: Node) -> void:
	object_detected.emit(object)


func report_ally_detected(ally: Node) -> void:
	ally_detected.emit(ally)


func report_enemy_detected(enemy: Node) -> void:
	enemy_detected.emit(enemy)
