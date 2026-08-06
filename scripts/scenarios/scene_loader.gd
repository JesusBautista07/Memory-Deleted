class_name SceneLoader
extends RefCounted

signal load_started(scene_id: String)
signal load_finished(scene_id: String, instance: Node)
signal load_failed(scene_id: String, error: String)
signal unload_started(scene_id: String)
signal unload_finished(scene_id: String)


func load_scene(data: SceneData) -> Node:
	if data == null or data.main_scene == null:
		load_failed.emit(data.scene_id if data != null else "", "SceneData o main_scene inválido")
		return null

	load_started.emit(data.scene_id)
	var instance: Node = data.main_scene.instantiate()
	if instance == null:
		load_failed.emit(data.scene_id, "No se pudo instanciar la escena principal")
		return null

	load_finished.emit(data.scene_id, instance)
	return instance


func unload_scene(scene_id: String, instance: Node) -> void:
	if instance == null:
		return
	unload_started.emit(scene_id)
	if instance.is_inside_tree() and instance.get_parent() != null:
		instance.get_parent().remove_child(instance)
	instance.queue_free()
	unload_finished.emit(scene_id)


func prepare_streaming(data: SceneData) -> void:
	pass
