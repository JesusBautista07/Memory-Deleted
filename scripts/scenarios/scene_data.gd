class_name SceneData
extends Resource

@export var scene_id: String = ""
@export var scene_name: String = ""
@export var description: String = ""
@export var scene_type: String = ""

@export var main_scene: PackedScene
@export var spawn_point_id: String = ""
@export var initial_checkpoint_id: String = ""

@export var lighting_profile: String = ""
@export var ambient_profile: String = ""
@export var audio_profile: String = ""
@export var ai_profile: String = ""
@export var events_profile: String = ""
@export var navigation_profile: String = ""

@export var custom_data: Dictionary = {}


func get_custom_value(key: String, default_value: Variant = null) -> Variant:
	return custom_data.get(key, default_value)


func set_custom_value(key: String, value: Variant) -> void:
	custom_data[key] = value
