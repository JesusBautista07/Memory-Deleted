extends PickupObject
class_name VoiceRecorderItem

signal play_requested(recording_id: String, audio_stream: AudioStream)

@export var audio_stream: AudioStream
@export var play_on_pickup: bool = false

func interact() -> void:
	super.interact()
	if play_on_pickup:
		request_play()

func request_play() -> void:
	play_requested.emit(get_object_id(), audio_stream)
