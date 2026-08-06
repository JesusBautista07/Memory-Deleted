class_name SceneRegistry
extends RefCounted

var _scenarios: Dictionary = {}


func register(data: SceneData) -> void:
	if data == null or data.scene_id.is_empty():
		return
	_scenarios[data.scene_id] = data


func unregister(scene_id: String) -> void:
	_scenarios.erase(scene_id)


func is_registered(scene_id: String) -> bool:
	return _scenarios.has(scene_id)


func get_scene_data(scene_id: String) -> SceneData:
	return _scenarios.get(scene_id, null)


func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _scenarios.keys():
		ids.append(key)
	return ids


func get_all_scene_data() -> Array[SceneData]:
	var result: Array[SceneData] = []
	for key in _scenarios.keys():
		result.append(_scenarios[key])
	return result
