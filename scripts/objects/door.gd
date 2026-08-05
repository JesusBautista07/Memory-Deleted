extends Node3D
## Sistema de puertas. Responsabilidad única: controlar el estado
## (abierta/cerrada/bloqueada) de ESTA puerta y notificarlo mediante señales.
## No gestiona input, inventario, UI ni eventos reales — solo expone
## los puntos de conexión para que esos sistemas se integren después.

signal door_opened
signal door_closed
signal door_locked(required_key: String)   ## se emite cuando se intenta abrir sin la llave correcta
signal event_triggered(event_name: String) ## para que un futuro EventManager se conecte

enum State { CLOSED, OPENING, OPEN, CLOSING }

## --- Configuración desde el Inspector ---
@export var key_id: String = ""              ## ID de la llave requerida. Vacío = no requiere llave.
@export var starts_locked: bool = false
@export var open_speed: float = 1.0           ## segundos que tarda en abrir/cerrar
@export var open_angle: float = 90.0          ## grados de apertura
@export var sound_open: AudioStream
@export var sound_close: AudioStream
@export var triggers_event: bool = false
@export var event_name: String = ""

@onready var pivot: Node3D = $DoorPivot
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var is_locked: bool = false
var _state: State = State.CLOSED
var _tween: Tween


func _ready() -> void:
	is_locked = starts_locked


## Punto de entrada público único. El futuro sistema de Interacción llama
## a esta función pasando las llaves que el jugador posee (desde Inventario).
## available_keys: Array de Strings con los IDs de llaves del jugador.
func try_open(available_keys: Array = []) -> bool:
	if _state == State.OPEN or _state == State.OPENING:
		close()
		return true

	if is_locked:
		if key_id != "" and available_keys.has(key_id):
			unlock()
		else:
			door_locked.emit(key_id)
			return false

	open()
	return true


func open() -> void:
	if _state == State.OPEN or _state == State.OPENING:
		return

	_state = State.OPENING
	_play_sound(sound_open)

	_tween = create_tween()
	_tween.tween_property(pivot, "rotation_degrees:y", open_angle, open_speed) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.finished.connect(_on_open_finished)


func close() -> void:
	if _state == State.CLOSED or _state == State.CLOSING:
		return

	_state = State.CLOSING
	_play_sound(sound_close)

	_tween = create_tween()
	_tween.tween_property(pivot, "rotation_degrees:y", 0.0, open_speed) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.finished.connect(_on_close_finished)


func lock() -> void:
	is_locked = true


func unlock() -> void:
	is_locked = false


func _on_open_finished() -> void:
	_state = State.OPEN
	door_opened.emit()
	if triggers_event:
		event_triggered.emit(event_name)


func _on_close_finished() -> void:
	_state = State.CLOSED
	door_closed.emit()


func _play_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	audio_player.stream = stream
	audio_player.play()
