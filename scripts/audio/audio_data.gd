extends Resource
class_name AudioData

enum AudioType {
	BGM,
	SFX,
	AMBIENT,
	VOICE,
	UI,
}

@export var audio_id: String = ""
@export var audio_name: String = ""
@export var audio_type: AudioType = AudioType.SFX
@export var stream: AudioStream
@export var volume_db: float = 0.0
@export var pitch_scale: float = 1.0
@export var loop: bool = false
