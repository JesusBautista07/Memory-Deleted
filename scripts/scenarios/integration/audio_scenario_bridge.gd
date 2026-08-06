class_name AudioScenarioBridge
extends ScenarioIntegrationBridge

## Ticket 013C — Integración del Sistema de Audio con el Sistema de
## Escenarios.
##
## SceneData ya expone un campo `audio_profile` (ver scene_data.gd)
## pensado para identificar el audio_id de música de fondo asociado a
## cada escenario. Este bridge se limita a leer ese dato y llamar a la
## API pública que AudioManager ya expone:
##   - play_bgm(audio_id) al cargar el escenario.
##   - stop_bgm() al empezar a descargarlo.
##
## AudioManager se localiza por su propio grupo ya existente
## ("audio_manager", const GROUP_NAME en audio_manager.gd). No se
## edita audio_manager.gd ni se implementa lógica de audio nueva aquí:
## solo se orquesta la llamada a métodos que ya existían.

const AUDIO_MANAGER_GROUP: String = "audio_manager"


func _on_scenario_loaded(_scene_id: String, data: SceneData) -> void:
	if data == null or data.audio_profile.is_empty():
		return

	var audio_manager: Node = _find_system(AUDIO_MANAGER_GROUP)
	if audio_manager == null:
		return

	if audio_manager.has_method("has_sound") and not audio_manager.has_sound(data.audio_profile):
		return

	_call_if_supported(audio_manager, "play_bgm", [data.audio_profile])


func _on_scenario_unload_started(_scene_id: String) -> void:
	var audio_manager: Node = _find_system(AUDIO_MANAGER_GROUP)
	_call_if_supported(audio_manager, "stop_bgm")
