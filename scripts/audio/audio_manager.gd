extends Node
class_name AudioManager

signal sound_registered(audio_id: String)
signal bgm_changed(audio_id: String)
signal bgm_stopped
signal ambient_played(audio_id: String)
signal voice_played(audio_id: String)
signal sfx_played(audio_id: String)
signal ui_sound_played(audio_id: String)

const GROUP_NAME := "audio_manager"

@export var sfx_pool_size: int = 8
@export var initial_sounds: Array[AudioData] = []

var _registry: Dictionary = {}

var _bgm_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _voice_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []

var _category_volume: Dictionary = {
	AudioData.AudioType.BGM: 1.0,
	AudioData.AudioType.SFX: 1.0,
	AudioData.AudioType.AMBIENT: 1.0,
	AudioData.AudioType.VOICE: 1.0,
	AudioData.AudioType.UI: 1.0,
}

func _ready() -> void:
	add_to_group(GROUP_NAME)
	_build_players()
	register_sounds(initial_sounds)

func _build_players() -> void:
	_bgm_player = _create_player("BGMPlayer")
	_ambient_player = _create_player("AmbientPlayer")
	_voice_player = _create_player("VoicePlayer")
	_ui_player = _create_player("UIPlayer")

	for i in range(sfx_pool_size):
		_sfx_players.append(_create_player("SFXPlayer%d" % i))

func _create_player(node_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	add_child(player)
	return player

func register_sound(audio_data: AudioData) -> void:
	if audio_data == null or audio_data.audio_id.is_empty():
		return
	_registry[audio_data.audio_id] = audio_data
	sound_registered.emit(audio_data.audio_id)

func register_sounds(audio_list: Array[AudioData]) -> void:
	for data in audio_list:
		register_sound(data)

func unregister_sound(audio_id: String) -> void:
	_registry.erase(audio_id)

func has_sound(audio_id: String) -> bool:
	return _registry.has(audio_id)

func get_sound_data(audio_id: String) -> AudioData:
	return _registry.get(audio_id)

func play_sound(audio_id: String) -> void:
	var data: AudioData = get_sound_data(audio_id)
	if data == null:
		return

	match data.audio_type:
		AudioData.AudioType.BGM:
			play_bgm(audio_id)
		AudioData.AudioType.SFX:
			play_sfx(audio_id)
		AudioData.AudioType.AMBIENT:
			play_ambient(audio_id)
		AudioData.AudioType.VOICE:
			play_voice(audio_id)
		AudioData.AudioType.UI:
			play_ui(audio_id)

func play_bgm(audio_id: String) -> void:
	var data: AudioData = get_sound_data(audio_id)
	if data == null or data.stream == null:
		return

	_bgm_player.stream = data.stream
	_bgm_player.volume_db = data.volume_db + _category_to_db(AudioData.AudioType.BGM)
	_bgm_player.pitch_scale = data.pitch_scale
	_bgm_player.play()
	bgm_changed.emit(audio_id)

func stop_bgm() -> void:
	_bgm_player.stop()
	bgm_stopped.emit()

func play_ambient(audio_id: String) -> void:
	var data: AudioData = get_sound_data(audio_id)
	if data == null or data.stream == null:
		return

	_ambient_player.stream = data.stream
	_ambient_player.volume_db = data.volume_db + _category_to_db(AudioData.AudioType.AMBIENT)
	_ambient_player.pitch_scale = data.pitch_scale
	_ambient_player.play()
	ambient_played.emit(audio_id)

func stop_ambient() -> void:
	_ambient_player.stop()

func play_voice(audio_id: String) -> void:
	var data: AudioData = get_sound_data(audio_id)
	if data == null or data.stream == null:
		return

	_voice_player.stream = data.stream
	_voice_player.volume_db = data.volume_db + _category_to_db(AudioData.AudioType.VOICE)
	_voice_player.pitch_scale = data.pitch_scale
	_voice_player.play()
	voice_played.emit(audio_id)

func stop_voice() -> void:
	_voice_player.stop()

func play_ui(audio_id: String) -> void:
	var data: AudioData = get_sound_data(audio_id)
	if data == null or data.stream == null:
		return

	_ui_player.stream = data.stream
	_ui_player.volume_db = data.volume_db + _category_to_db(AudioData.AudioType.UI)
	_ui_player.pitch_scale = data.pitch_scale
	_ui_player.play()
	ui_sound_played.emit(audio_id)

func play_sfx(audio_id: String) -> void:
	var data: AudioData = get_sound_data(audio_id)
	if data == null or data.stream == null:
		return

	var player: AudioStreamPlayer = _get_free_sfx_player()
	if player == null:
		return

	player.stream = data.stream
	player.volume_db = data.volume_db + _category_to_db(AudioData.AudioType.SFX)
	player.pitch_scale = data.pitch_scale
	player.play()
	sfx_played.emit(audio_id)

func stop_all_sfx() -> void:
	for player in _sfx_players:
		player.stop()

func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	return _sfx_players[0] if _sfx_players.size() > 0 else null

func set_category_volume(audio_type: AudioData.AudioType, linear_volume: float) -> void:
	_category_volume[audio_type] = clampf(linear_volume, 0.0, 1.0)

func get_category_volume(audio_type: AudioData.AudioType) -> float:
	return _category_volume.get(audio_type, 1.0)

func _category_to_db(audio_type: AudioData.AudioType) -> float:
	var linear_volume: float = _category_volume.get(audio_type, 1.0)
	if linear_volume <= 0.0:
		return -80.0
	return linear_to_db(linear_volume)
