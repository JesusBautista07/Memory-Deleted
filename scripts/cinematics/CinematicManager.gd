class_name CinematicManager
extends RefCounted
## Administrador general del Sistema de Cinemáticas.
##
## Mantiene el registro y la organización de todas las piezas del
## sistema (cinemáticas, secuencias, triggers, configuraciones de
## cámara y reproductores), delegando el almacenamiento de
## CinematicData en un CinematicRegistry compuesto internamente.
## También orquesta la cola de reproducción: cuando se solicita
## reproducir una CinematicSequence, la asigna a un CinematicPlayer
## libre (registrado previamente) o la encola según su prioridad,
## sincronizándose con cada CinematicPlayer a través de sus propias
## señales para saber cuándo queda libre.
##
## El Manager no reproduce nada por sí mismo (delega toda la
## reproducción real en los CinematicPlayer que administra), no tiene
## _process propio y no controla el tiempo: solo decide QUÉ secuencia
## se asigna a QUÉ reproductor y en QUÉ orden.
##
## Es una clase instanciable de forma independiente (no es un Autoload
## ni asume serlo); la integración como singleton, si corresponde,
## queda a cargo del proyecto principal.
##
## PUNTOS DE INTEGRACIÓN (Ticket 015B-2)
## --------------------------------------------------------------
## Este Manager NO conoce ni depende de ningún sistema externo (Audio,
## Ambientación, Eventos, Escenarios, Guardado, IA, Jugador, UI,
## Objetos, Documentos, Puertas, Puzzles, Cámara). En su lugar expone
## señales "request_*" que esos sistemas pueden escuchar de forma
## opcional y completamente desacoplada (ningún Autoload, ninguna
## referencia a nodos concretos).
##
## Las señales ligadas al ciclo de vida de la reproducción (bloqueo y
## restauración de controles/UI, pausa y reanudación de IA, cambio y
## restauración de cámara, arranque y detención de audio, subtítulos,
## ambientación) se reenvían automáticamente a partir de las señales
## de ciclo de vida ya existentes en cada CinematicPlayer registrado
## (playback_started / playback_finished / playback_cancelled /
## playback_skipped / playback_paused / playback_resumed). El Manager
## solo reenvía: no decide qué hace cada sistema externo con ellas.
##
## Las señales que no tienen un momento único y automático dentro del
## ciclo de vida (ejecutar un evento, guardar progreso, cargar un
## escenario) se exponen además como métodos públicos "request_*",
## para que quien orqueste el contenido de una secuencia (por ejemplo,
## un futuro marcador dentro de CinematicSequence o CinematicTrigger)
## pueda invocarlas en el momento que corresponda, sin que este Manager
## necesite conocer esa estructura interna.

## Registro de CinematicData (reutiliza CinematicRegistry sin modificarlo).
var _registry: CinematicRegistry = CinematicRegistry.new()

## Secuencias registradas: sequence_id (StringName) -> CinematicSequence.
var _sequences: Dictionary = {}

## Triggers registrados: trigger_id (StringName) -> CinematicTrigger.
var _triggers: Dictionary = {}

## Configuraciones de cámara registradas: camera_id (StringName) -> CinematicCamera.
var _cameras: Dictionary = {}

## Reproductores registrados: player_id (StringName) -> CinematicPlayer.
var _players: Dictionary = {}

## Cola de solicitudes de reproducción pendientes, ordenada de mayor a
## menor prioridad. Cada elemento es un Dictionary con las claves:
## "sequence" (CinematicSequence), "context" (CinematicContext o null),
## "priority" (int) y "auto_play" (bool).
var _queue: Array[Dictionary] = []

# ------------------------------------------------------------------
# Señales de integración: Jugador
# ------------------------------------------------------------------

## Solicita que el Sistema del Jugador bloquee sus controles.
signal request_player_controls_lock(context: CinematicContext)

## Solicita que el Sistema del Jugador restaure sus controles.
signal request_player_controls_restore(context: CinematicContext)

# ------------------------------------------------------------------
# Señales de integración: IA
# ------------------------------------------------------------------

## Solicita que el Sistema de IA pause su actividad.
signal request_ai_pause(context: CinematicContext)

## Solicita que el Sistema de IA reactive su actividad.
signal request_ai_resume(context: CinematicContext)

# ------------------------------------------------------------------
# Señales de integración: Cámara
# ------------------------------------------------------------------

## Solicita al Sistema de Cámara un cambio hacia la cámara de la cinemática.
signal request_camera_change(context: CinematicContext)

## Solicita al Sistema de Cámara restaurar la cámara previa a la cinemática.
signal request_camera_restore(context: CinematicContext)

# ------------------------------------------------------------------
# Señales de integración: Audio
# ------------------------------------------------------------------

## Solicita al Sistema de Audio la reproducción asociada a la cinemática.
signal request_audio_play(context: CinematicContext)

## Solicita al Sistema de Audio detener la reproducción asociada.
signal request_audio_stop(context: CinematicContext)

# ------------------------------------------------------------------
# Señales de integración: Ambientación
# ------------------------------------------------------------------

## Solicita al Sistema de Ambientación un cambio de perfil ambiental.
signal request_ambient_change(context: CinematicContext)

# ------------------------------------------------------------------
# Señales de integración: Eventos
# ------------------------------------------------------------------

## Solicita al Sistema de Eventos la ejecución de un evento asociado
## a la cinemática. No se dispara automáticamente: se invoca a través
## de request_event_execute().
signal request_event_execute(event_id: StringName, context: CinematicContext)

# ------------------------------------------------------------------
# Señales de integración: Guardado
# ------------------------------------------------------------------

## Solicita al Sistema de Guardado guardar el progreso actual. No se
## dispara automáticamente: se invoca a través de request_save_progress().
signal request_progress_save(context: CinematicContext)

# ------------------------------------------------------------------
# Señales de integración: Escenarios
# ------------------------------------------------------------------

## Solicita al Sistema de Escenarios cargar un escenario. No se dispara
## automáticamente: se invoca a través de request_scenario_load().
signal request_scenario_load(scenario_id: StringName, context: CinematicContext)

# ------------------------------------------------------------------
# Señales de integración: UI
# ------------------------------------------------------------------

## Solicita al Sistema UI bloquear su interacción durante la cinemática.
signal request_ui_lock(context: CinematicContext)

## Solicita al Sistema UI restaurar su interacción tras la cinemática.
signal request_ui_restore(context: CinematicContext)

# ------------------------------------------------------------------
# Señales de integración: Subtítulos
# ------------------------------------------------------------------

## Solicita activar/mostrar subtítulos para la cinemática en curso.
signal request_subtitles_show(context: CinematicContext)

## Solicita desactivar/ocultar subtítulos.
signal request_subtitles_hide(context: CinematicContext)


## Devuelve el CinematicRegistry compuesto internamente, para que
## sistemas externos puedan registrar/consultar CinematicData a
## través del administrador.
func get_registry() -> CinematicRegistry:
	return _registry


# ------------------------------------------------------------------
# Secuencias
# ------------------------------------------------------------------

## Registra una secuencia. Devuelve false si es inválida o carece de id.
func register_sequence(sequence: CinematicSequence) -> bool:
	if sequence == null:
		return false
	if sequence.sequence_id == &"":
		return false

	_sequences[sequence.sequence_id] = sequence
	return true


## Elimina del registro la secuencia asociada a un id.
func unregister_sequence(sequence_id: StringName) -> bool:
	if not _sequences.has(sequence_id):
		return false

	_sequences.erase(sequence_id)
	return true


## Devuelve la secuencia asociada a un id, o null si no existe.
func find_sequence(sequence_id: StringName) -> CinematicSequence:
	if not _sequences.has(sequence_id):
		return null
	return _sequences[sequence_id]


## Devuelve todas las secuencias registradas.
func get_all_sequences() -> Array[CinematicSequence]:
	var result: Array[CinematicSequence] = []
	for key in _sequences.keys():
		result.append(_sequences[key])
	return result


# ------------------------------------------------------------------
# Triggers
# ------------------------------------------------------------------

## Registra un trigger. Devuelve false si es inválido o carece de id.
func register_trigger(trigger: CinematicTrigger) -> bool:
	if trigger == null:
		return false
	if trigger.trigger_id == &"":
		return false

	_triggers[trigger.trigger_id] = trigger
	return true


## Elimina del registro el trigger asociado a un id.
func unregister_trigger(trigger_id: StringName) -> bool:
	if not _triggers.has(trigger_id):
		return false

	_triggers.erase(trigger_id)
	return true


## Devuelve el trigger asociado a un id, o null si no existe.
func find_trigger(trigger_id: StringName) -> CinematicTrigger:
	if not _triggers.has(trigger_id):
		return null
	return _triggers[trigger_id]


## Devuelve todos los triggers registrados que apuntan a una cinemática dada.
func find_triggers_by_cinematic(cinematic_id: StringName) -> Array[CinematicTrigger]:
	var result: Array[CinematicTrigger] = []
	for key in _triggers.keys():
		var trigger: CinematicTrigger = _triggers[key]
		if trigger.cinematic_id == cinematic_id:
			result.append(trigger)
	return result


## Devuelve todos los triggers registrados.
func get_all_triggers() -> Array[CinematicTrigger]:
	var result: Array[CinematicTrigger] = []
	for key in _triggers.keys():
		result.append(_triggers[key])
	return result


# ------------------------------------------------------------------
# Configuraciones de cámara
# ------------------------------------------------------------------

## Registra una configuración de cámara. Devuelve false si es inválida.
func register_camera(camera: CinematicCamera) -> bool:
	if camera == null:
		return false
	if camera.camera_id == &"":
		return false

	_cameras[camera.camera_id] = camera
	return true


## Elimina del registro la configuración de cámara asociada a un id.
func unregister_camera(camera_id: StringName) -> bool:
	if not _cameras.has(camera_id):
		return false

	_cameras.erase(camera_id)
	return true


## Devuelve la configuración de cámara asociada a un id, o null si no existe.
func find_camera(camera_id: StringName) -> CinematicCamera:
	if not _cameras.has(camera_id):
		return null
	return _cameras[camera_id]


## Devuelve todas las configuraciones de cámara registradas.
func get_all_cameras() -> Array[CinematicCamera]:
	var result: Array[CinematicCamera] = []
	for key in _cameras.keys():
		result.append(_cameras[key])
	return result


# ------------------------------------------------------------------
# Reproductores
# ------------------------------------------------------------------

## Registra un reproductor. Devuelve false si es inválido o carece de id.
## Se sincroniza con result_set del reproductor para saber cuándo queda
## libre y así continuar procesando la cola de reproducción, y con sus
## señales de ciclo de vida para reenviar los puntos de integración
## desacoplados (ver cabecera de este archivo).
func register_player(player: CinematicPlayer) -> bool:
	if player == null:
		return false
	if player.player_id == &"":
		return false

	if not player.result_set.is_connected(_on_player_result_set):
		player.result_set.connect(_on_player_result_set)
	_connect_player_integration_signals(player)

	_players[player.player_id] = player
	_process_queue()
	return true


## Elimina del registro el reproductor asociado a un id, desconectando
## la sincronización establecida al registrarlo.
func unregister_player(player_id: StringName) -> bool:
	if not _players.has(player_id):
		return false

	var player: CinematicPlayer = _players[player_id]
	if player.result_set.is_connected(_on_player_result_set):
		player.result_set.disconnect(_on_player_result_set)
	_disconnect_player_integration_signals(player)

	_players.erase(player_id)
	return true


## Devuelve el reproductor asociado a un id, o null si no existe.
func find_player(player_id: StringName) -> CinematicPlayer:
	if not _players.has(player_id):
		return null
	return _players[player_id]


## Devuelve todos los reproductores registrados.
func get_all_players() -> Array[CinematicPlayer]:
	var result: Array[CinematicPlayer] = []
	for key in _players.keys():
		result.append(_players[key])
	return result


# ------------------------------------------------------------------
# Cola de reproducción y prioridad
# ------------------------------------------------------------------

## Solicita la reproducción de una secuencia. Si existe un CinematicPlayer
## registrado que esté libre, se le asigna la secuencia de inmediato
## (auto_play decide si además se llama a play() o solo se carga para
## reproducción manual). Si no hay ningún reproductor libre, la solicitud
## se encola respetando la prioridad indicada (mayor prioridad, antes en
## la cola). Devuelve false si la secuencia es inválida.
func request_playback(
	sequence: CinematicSequence,
	context: CinematicContext = null,
	priority: int = 0,
	auto_play: bool = true
) -> bool:
	if sequence == null:
		return false

	var request: Dictionary = {
		"sequence": sequence,
		"context": context,
		"priority": priority,
		"auto_play": auto_play,
	}
	_enqueue(request)
	_process_queue()
	return true


## Elimina todas las solicitudes pendientes cuya secuencia tenga el
## cinematic_id indicado. Devuelve la cantidad de solicitudes eliminadas.
func remove_from_queue(cinematic_id: StringName) -> int:
	var removed_count: int = 0
	var i: int = _queue.size() - 1
	while i >= 0:
		var request: Dictionary = _queue[i]
		var sequence: CinematicSequence = request["sequence"]
		if sequence != null and sequence.cinematic_id == cinematic_id:
			_queue.remove_at(i)
			removed_count += 1
		i -= 1
	return removed_count


## Elimina todas las solicitudes pendientes de la cola, sin afectar a
## los reproductores que ya estén en curso.
func clear_queue() -> void:
	_queue.clear()


## Devuelve la cantidad de solicitudes pendientes en la cola.
func get_queue_size() -> int:
	return _queue.size()


## Inserta una solicitud en la cola respetando el orden por prioridad
## (mayor prioridad, antes en la cola). Entre solicitudes de igual
## prioridad, se conserva el orden de llegada (FIFO).
func _enqueue(request: Dictionary) -> void:
	var insert_index: int = _queue.size()
	for i in _queue.size():
		if request["priority"] > _queue[i]["priority"]:
			insert_index = i
			break

	_queue.insert(insert_index, request)


## Busca, entre los reproductores registrados, uno que esté libre
## (sin secuencia cargada o en un estado terminal).
func _find_idle_player() -> CinematicPlayer:
	for key in _players.keys():
		var player: CinematicPlayer = _players[key]
		var state: int = player.get_state()
		if not player.has_sequence():
			return player
		if (
			state == CinematicState.FINISHED
			or state == CinematicState.CANCELLED
			or state == CinematicState.SKIPPED
			or state == CinematicState.FAILED
		):
			return player
	return null


## Mientras haya solicitudes pendientes y reproductores libres, asigna
## la solicitud de mayor prioridad al siguiente reproductor disponible.
func _process_queue() -> void:
	while not _queue.is_empty():
		var idle_player: CinematicPlayer = _find_idle_player()
		if idle_player == null:
			return

		var request: Dictionary = _queue.pop_front()
		idle_player.load_sequence(request["sequence"])
		idle_player.set_context(request["context"])
		if request["auto_play"]:
			idle_player.play()


## Reacciona a que un reproductor registrado haya producido un resultado
## (quedando así libre) para continuar procesando la cola de reproducción.
func _on_player_result_set(_result: CinematicResult) -> void:
	_process_queue()


# ------------------------------------------------------------------
# Integración desacoplada (Ticket 015B-2)
# ------------------------------------------------------------------

## Conecta las señales de ciclo de vida de un CinematicPlayer a los
## manejadores internos que reenvían los puntos de integración. Solo
## reenvía: no implementa ninguna lógica de los sistemas externos.
func _connect_player_integration_signals(player: CinematicPlayer) -> void:
	if not player.playback_started.is_connected(_on_player_playback_started):
		player.playback_started.connect(_on_player_playback_started)
	if not player.playback_finished.is_connected(_on_player_playback_finished):
		player.playback_finished.connect(_on_player_playback_finished)
	if not player.playback_cancelled.is_connected(_on_player_playback_cancelled):
		player.playback_cancelled.connect(_on_player_playback_cancelled)
	if not player.playback_skipped.is_connected(_on_player_playback_skipped):
		player.playback_skipped.connect(_on_player_playback_skipped)
	if not player.playback_paused.is_connected(_on_player_playback_paused):
		player.playback_paused.connect(_on_player_playback_paused)
	if not player.playback_resumed.is_connected(_on_player_playback_resumed):
		player.playback_resumed.connect(_on_player_playback_resumed)


## Desconecta las señales de ciclo de vida conectadas en
## _connect_player_integration_signals().
func _disconnect_player_integration_signals(player: CinematicPlayer) -> void:
	if player.playback_started.is_connected(_on_player_playback_started):
		player.playback_started.disconnect(_on_player_playback_started)
	if player.playback_finished.is_connected(_on_player_playback_finished):
		player.playback_finished.disconnect(_on_player_playback_finished)
	if player.playback_cancelled.is_connected(_on_player_playback_cancelled):
		player.playback_cancelled.disconnect(_on_player_playback_cancelled)
	if player.playback_skipped.is_connected(_on_player_playback_skipped):
		player.playback_skipped.disconnect(_on_player_playback_skipped)
	if player.playback_paused.is_connected(_on_player_playback_paused):
		player.playback_paused.disconnect(_on_player_playback_paused)
	if player.playback_resumed.is_connected(_on_player_playback_resumed):
		player.playback_resumed.disconnect(_on_player_playback_resumed)


## Al iniciar la reproducción: solicita bloqueo de controles del jugador,
## pausa de IA, cambio de cámara, audio, ambientación, bloqueo de UI y
## subtítulos. Cada sistema externo decide si atiende o ignora la señal.
func _on_player_playback_started(_sequence: CinematicSequence, context: CinematicContext) -> void:
	request_player_controls_lock.emit(context)
	request_ai_pause.emit(context)
	request_camera_change.emit(context)
	request_audio_play.emit(context)
	request_ambient_change.emit(context)
	request_ui_lock.emit(context)
	request_subtitles_show.emit(context)


## Al finalizar la reproducción de forma natural: solicita restaurar
## controles, IA, cámara, detener audio, restaurar UI y ocultar subtítulos.
func _on_player_playback_finished(_result: CinematicResult, context: CinematicContext) -> void:
	_request_lifecycle_teardown(context)


## Al cancelarse la reproducción: mismo reenvío de restauración que al
## finalizar de forma natural.
func _on_player_playback_cancelled(_result: CinematicResult, context: CinematicContext) -> void:
	_request_lifecycle_teardown(context)


## Al saltarse la reproducción: mismo reenvío de restauración que al
## finalizar de forma natural.
func _on_player_playback_skipped(_result: CinematicResult, context: CinematicContext) -> void:
	_request_lifecycle_teardown(context)


## Al pausarse la reproducción: no se restauran controles ni IA (la
## cinemática sigue activa, solo detenida en el tiempo); se reenvía tal
## cual para que sistemas externos que lo necesiten puedan reaccionar
## (por ejemplo, pausar el audio de la cinemática).
func _on_player_playback_paused(context: CinematicContext) -> void:
	request_audio_stop.emit(context)


## Al reanudarse la reproducción tras una pausa.
func _on_player_playback_resumed(context: CinematicContext) -> void:
	request_audio_play.emit(context)


## Agrupa el reenvío común a finalización, cancelación y salto: restaura
## controles del jugador, reactiva IA, restaura cámara, detiene audio,
## restaura UI y oculta subtítulos.
func _request_lifecycle_teardown(context: CinematicContext) -> void:
	request_player_controls_restore.emit(context)
	request_ai_resume.emit(context)
	request_camera_restore.emit(context)
	request_audio_stop.emit(context)
	request_ui_restore.emit(context)
	request_subtitles_hide.emit(context)


## Solicita al Sistema de Eventos la ejecución de un evento asociado a la
## cinemática en curso. No implementa el evento: solo reenvía la solicitud
## mediante request_event_execute. Pensado para ser invocado por quien
## orqueste el contenido de la secuencia (marcador, trigger, etc.).
func request_event_execution(event_id: StringName, context: CinematicContext = null) -> void:
	request_event_execute.emit(event_id, context)


## Solicita al Sistema de Guardado guardar el progreso actual. No
## implementa el guardado: solo reenvía la solicitud mediante
## request_progress_save.
func request_save_progress(context: CinematicContext = null) -> void:
	request_progress_save.emit(context)


## Solicita al Sistema de Escenarios cargar un escenario. No implementa
## la carga: solo reenvía la solicitud mediante request_scenario_load.
func request_scenario_loading(scenario_id: StringName, context: CinematicContext = null) -> void:
	request_scenario_load.emit(scenario_id, context)


# ------------------------------------------------------------------
# Utilidades generales
# ------------------------------------------------------------------

## Elimina todo lo registrado en el administrador (cinemáticas, secuencias,
## triggers, cámaras, reproductores y la cola de reproducción). Solo
## limpia estructura, no detiene ninguna reproducción en curso.
func clear_all() -> void:
	_registry.clear()
	_sequences.clear()
	_triggers.clear()
	_cameras.clear()
	_players.clear()
	_queue.clear()
