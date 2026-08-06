class_name AIScenarioBridge
extends ScenarioIntegrationBridge

## Ticket 013C — Integración del Sistema de IA con el Sistema de
## Escenarios.
##
## SceneData ya expone un campo `ai_profile` (ver scene_data.gd)
## pensado para identificar el estado inicial de IA asociado a cada
## escenario. Este bridge se limita a leer ese dato y llamarlo sobre
## la API pública que AIController ya expone: change_state(state_name).
##
## AIController no se registra a sí mismo en ningún grupo (cada
## instancia representa a un único personaje/enemigo, no es un
## manager central), así que este bridge asume el grupo
## "ai_controller" como convención de integración: los AIController
## que deban reaccionar a los escenarios se añaden a ese grupo desde
## el editor de escenas, igual que ya se hace con los grupos
## "saveable_*" del Sistema de Guardado. No se edita ai_controller.gd.

const AI_CONTROLLER_GROUP: String = "ai_controller"


func _on_scenario_loaded(_scene_id: String, data: SceneData) -> void:
	if data == null or data.ai_profile.is_empty():
		return

	for controller in get_tree().get_nodes_in_group(AI_CONTROLLER_GROUP):
		_call_if_supported(controller, "change_state", [data.ai_profile])
