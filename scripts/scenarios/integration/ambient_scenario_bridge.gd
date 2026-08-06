class_name AmbientScenarioBridge
extends ScenarioIntegrationBridge

## Ticket 013C — Integración del Sistema de Ambientación con el
## Sistema de Escenarios.
##
## SceneData ya expone un campo `ambient_profile` (ver scene_data.gd)
## pensado para identificar el perfil de ambientación asociado a cada
## escenario. Este bridge se limita a leer ese dato y llamar a la API
## pública que AmbientManager ya expone:
##   - apply_profile(profile_name) al cargar el escenario, si el
##     perfil ya está registrado en AmbientManager.
##   - clear_profile() al empezar a descargar el escenario, para
##     volver a un estado neutro.
##
## AmbientManager se localiza por su propio grupo ya existente
## ("ambient_manager", const GROUP_NAME en ambient_manager.gd). No se
## edita ambient_manager.gd ni se implementa lógica de ambientación
## nueva aquí: solo se orquesta la llamada a métodos que ya existían.

const AMBIENT_MANAGER_GROUP: String = "ambient_manager"


func _on_scenario_loaded(_scene_id: String, data: SceneData) -> void:
	if data == null or data.ambient_profile.is_empty():
		return

	var ambient_manager: Node = _find_system(AMBIENT_MANAGER_GROUP)
	if ambient_manager == null:
		return

	if ambient_manager.has_method("has_profile") and not ambient_manager.has_profile(data.ambient_profile):
		return

	_call_if_supported(ambient_manager, "apply_profile", [data.ambient_profile])


func _on_scenario_unload_started(_scene_id: String) -> void:
	var ambient_manager: Node = _find_system(AMBIENT_MANAGER_GROUP)
	_call_if_supported(ambient_manager, "clear_profile")
