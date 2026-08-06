class_name CinematicPlayer
extends RefCounted
## Reproductor de cinemáticas: motor de reproducción de una CinematicSequence.
##
## Administra su propia máquina de estados (CinematicState), el avance del
## tiempo de reproducción y la construcción de su CinematicResult final.
## No mueve cámaras, no reproduce audio y no depende de ningún nodo de
## escena: no tiene _process propio. El avance del tiempo se produce
## exclusivamente a través de update(delta), que debe ser invocado por una
## capa externa (por ejemplo un Node del proyecto principal) en cada frame;
## esto mantiene el reproductor completamente desacoplado de la escena.
##
## Además de state_changed (genérica), expone señales de ciclo de vida
## específicas (inicio, finalización, cancelación, pausa, reanudación)
## pensadas como puntos de integración desacoplados para que sistemas
## externos (Audio, Ambientación, Eventos, Guardado, IA, Jugador, UI,
## Cámara, etc.) puedan reaccionar sin que este reproductor conozca su
## existencia. Este archivo no implementa dicha integración: solo la
## señaliza.

## Emitida cuando se carga una nueva secuencia en el reproductor.
signal sequence_loaded(sequence: CinematicSequence)

## Emitida cuando el estado público del reproductor cambia.
signal state_changed(previous_state: int, new_state: int)

## Emitida cuando se establece un resultado final en el reproductor.
signal result_set(result: CinematicResult)

## Emitida cuando la reproducción comienza (play() efectivo, desde el
## principio). Punto de integración para sistemas externos: bloqueo de
## controles del jugador, pausa de IA, cambio de cámara, arranque de
## audio, cambios de ambientación, bloqueo de UI, subtítulos, etc.
signal playback_started(sequence: CinematicSequence, context: CinematicContext)

## Emitida cuando la reproducción finaliza de forma natural (duración
## completa alcanzada). Punto de integración para restaurar controles,
## reactivar IA, restaurar cámara, detener audio, restaurar UI, etc.
signal playback_finished(result: CinematicResult, context: CinematicContext)

## Emitida cuando la reproducción se cancela explícitamente (stop()).
## Mismo propósito de integración que playback_finished, para el caso
## de interrupción en vez de finalización natural.
signal playback_cancelled(result: CinematicResult, context: CinematicContext)

## Emitida cuando la reproducción se salta (skip()). Se mantiene separada
## de playback_finished/playback_cancelled porque algunos sistemas
## externos (por ejemplo subtítulos o eventos) pueden necesitar
## distinguir un salto explícito del usuario.
signal playback_skipped(result: CinematicResult, context: CinematicContext)

## Emitida cuando la reproducción se pausa (pause()).
signal playback_paused(context: CinematicContext)

## Emitida cuando la reproducción se reanuda (resume()).
signal playback_resumed(context: CinematicContext)

## Identificador del reproductor (útil si existen múltiples instancias).
var player_id: StringName = &""

## Secuencia actualmente cargada en el reproductor (puede ser null).
var current_sequence: CinematicSequence = null

## Contexto actualmente asociado a la reproducción (puede ser null).
var current_context: CinematicContext = null

## Estado público actual del reproductor (ver CinematicState).
var current_state: int = CinematicState.NONE

## Último resultado producido por el reproductor (puede ser null).
var last_result: CinematicResult = null

## Tiempo transcurrido de reproducción, en segundos.
var playback_time: float = 0.0

## Velocidad de reproducción (1.0 = normal, 0.0 = detenida en el tiempo).
var playback_speed: float = 1.0


func _init(p_player_id: StringName = &"") -> void:
	player_id = p_player_id


## Carga una secuencia en el reproductor: asigna current_sequence, reinicia
## el tiempo de reproducción y el último resultado, y pasa a estado QUEUED.
## No inicia ninguna reproducción (para eso existe play()).
func load_sequence(sequence: CinematicSequence) -> void:
	current_sequence = sequence
	playback_time = 0.0
	last_result = null
	sequence_loaded.emit(sequence)
	set_state(CinematicState.QUEUED)


## Asigna el contexto de reproducción. Solo estructura pública, sin lógica.
func set_context(context: CinematicContext) -> void:
	current_context = context


## Devuelve el contexto de reproducción actualmente asignado.
func get_context() -> CinematicContext:
	return current_context


## Devuelve el estado público actual del reproductor.
func get_state() -> int:
	return current_state


## Asigna el estado público del reproductor y emite state_changed.
## Es solo un cambio de dato: no implica ninguna reproducción real.
func set_state(new_state: int) -> void:
	var previous_state: int = current_state
	current_state = new_state
	state_changed.emit(previous_state, new_state)


## Asigna el resultado final del reproductor y emite result_set.
func set_result(result: CinematicResult) -> void:
	last_result = result
	result_set.emit(result)


## Devuelve el último resultado producido por el reproductor.
func get_result() -> CinematicResult:
	return last_result


## Inicia la reproducción de la secuencia cargada desde el principio.
## No hace nada si no hay secuencia cargada o si ya está en PLAYING.
## Para reanudar desde PAUSED, usar resume(); para reiniciar en curso,
## usar restart().
func play() -> void:
	if current_sequence == null:
		return
	if current_state == CinematicState.PLAYING:
		return
	if current_state == CinematicState.PAUSED:
		return

	playback_time = 0.0
	last_result = null
	set_state(CinematicState.PLAYING)
	playback_started.emit(current_sequence, current_context)


## Pausa la reproducción. Solo tiene efecto si el estado actual es PLAYING.
func pause() -> void:
	if current_state != CinematicState.PLAYING:
		return

	set_state(CinematicState.PAUSED)
	playback_paused.emit(current_context)


## Reanuda la reproducción. Solo tiene efecto si el estado actual es PAUSED.
func resume() -> void:
	if current_state != CinematicState.PAUSED:
		return

	set_state(CinematicState.PLAYING)
	playback_resumed.emit(current_context)


## Reinicia la reproducción de la secuencia actual desde el principio,
## sin necesidad de volver a cargarla. No hace nada si no hay secuencia.
func restart() -> void:
	if current_sequence == null:
		return

	playback_time = 0.0
	last_result = null
	set_state(CinematicState.PLAYING)


## Detiene la reproducción de forma explícita (cancelación por el usuario
## o por un sistema externo). Construye y asigna el CinematicResult
## correspondiente con final_state = CANCELLED.
func stop() -> void:
	if current_state == CinematicState.NONE:
		return
	if _is_terminal_state(current_state):
		return

	var result := CinematicResult.new(
		_get_cinematic_id(),
		CinematicState.CANCELLED,
		false,
		false,
		playback_time,
		"",
		{}
	)
	set_state(CinematicState.CANCELLED)
	set_result(result)
	playback_cancelled.emit(result, current_context)


## Salta la cinemática actual, si el contexto lo permite (allow_skip).
## Solo tiene efecto mientras se está reproduciendo o en pausa.
## Construye y asigna el CinematicResult correspondiente con
## final_state = SKIPPED.
func skip() -> void:
	if current_state != CinematicState.PLAYING and current_state != CinematicState.PAUSED:
		return
	if current_context != null and not current_context.allow_skip:
		return

	var result := CinematicResult.new(
		_get_cinematic_id(),
		CinematicState.SKIPPED,
		false,
		true,
		playback_time,
		"",
		{}
	)
	set_state(CinematicState.SKIPPED)
	set_result(result)
	playback_skipped.emit(result, current_context)


## Avanza el tiempo de reproducción según playback_speed. Debe ser
## invocado externamente (por ejemplo desde el _process de un Node del
## proyecto principal); este reproductor no controla tiempo por sí mismo.
## Al alcanzar la duración total de la secuencia, finaliza automáticamente.
func update(delta: float) -> void:
	if current_state != CinematicState.PLAYING:
		return
	if current_sequence == null:
		return

	playback_time += delta * playback_speed

	var total_duration: float = get_duration()
	if total_duration > 0.0 and playback_time >= total_duration:
		playback_time = total_duration
		_finish()


## Duración total de la secuencia cargada, en segundos (0.0 si no hay
## secuencia cargada). Delegada en CinematicSequence.get_duration().
func get_duration() -> float:
	if current_sequence == null:
		return 0.0
	return current_sequence.get_duration()


## Tiempo transcurrido de reproducción, en segundos.
func get_elapsed_time() -> float:
	return playback_time


## Tiempo restante de reproducción, en segundos (nunca negativo).
func get_remaining_time() -> float:
	return maxf(get_duration() - playback_time, 0.0)


## Asigna la velocidad de reproducción (nunca negativa).
func set_playback_speed(speed: float) -> void:
	playback_speed = maxf(speed, 0.0)


## Devuelve la velocidad de reproducción actual.
func get_playback_speed() -> float:
	return playback_speed


## Indica si el reproductor tiene una secuencia cargada actualmente.
func has_sequence() -> bool:
	return current_sequence != null


## Indica si el reproductor se encuentra reproduciendo activamente.
func is_playing() -> bool:
	return current_state == CinematicState.PLAYING


## Indica si el reproductor está en pausa.
func is_paused() -> bool:
	return current_state == CinematicState.PAUSED


## Finaliza la reproducción de forma automática al completarse la
## duración de la secuencia. Construye y asigna el CinematicResult
## correspondiente con final_state = FINISHED y success = true.
func _finish() -> void:
	var result := CinematicResult.new(
		_get_cinematic_id(),
		CinematicState.FINISHED,
		true,
		false,
		playback_time,
		"",
		{}
	)
	set_state(CinematicState.FINISHED)
	set_result(result)
	playback_finished.emit(result, current_context)


## Devuelve el cinematic_id de la secuencia actualmente cargada, o ""
## si no hay ninguna secuencia cargada.
func _get_cinematic_id() -> StringName:
	if current_sequence == null:
		return &""
	return current_sequence.cinematic_id


## Indica si un estado dado es un estado terminal (ya finalizado de
## alguna forma: FINISHED, CANCELLED, SKIPPED o FAILED).
func _is_terminal_state(state: int) -> bool:
	return (
		state == CinematicState.FINISHED
		or state == CinematicState.CANCELLED
		or state == CinematicState.SKIPPED
		or state == CinematicState.FAILED
	)
