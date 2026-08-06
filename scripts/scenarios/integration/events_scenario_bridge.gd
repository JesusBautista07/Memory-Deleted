class_name EventsScenarioBridge
extends ScenarioIntegrationBridge

## Ticket 013C — Integración del Sistema de Eventos con el Sistema de
## Escenarios.
##
## Traduce el ciclo de vida de los escenarios en eventos del
## EventManager, para que sus manejadores por categoría
## (register_category_handler, ver event_manager.gd) puedan reaccionar
## sin depender de SceneManager ni de este bridge.
##
## EventManager se localiza por el grupo "event_manager", la misma
## convención que ya usan document_manager.gd e important_item.gd
## (const EVENT_MANAGER_GROUP := "event_manager"). Solo se usa su API
## pública ya existente (trigger_event). No se edita event_manager.gd
## ni se registra ningún evento de negocio nuevo: se reenvían los
## eventos del propio ciclo de vida del escenario.

const EVENT_MANAGER_GROUP: String = "event_manager"


func _on_scenario_loaded(scene_id: String, data: SceneData) -> void:
	var payload: Dictionary = {"scene_id": scene_id}
	if data != null:
		payload["events_profile"] = data.events_profile
	_trigger("scenario_loaded", payload)


func _on_scenario_unloaded(scene_id: String) -> void:
	_trigger("scenario_unloaded", {"scene_id": scene_id})


func _on_scenario_changed(previous_id: String, new_id: String) -> void:
	_trigger("scenario_changed", {"previous_id": previous_id, "new_id": new_id})


func _on_scenario_reset(scene_id: String) -> void:
	_trigger("scenario_reset", {"scene_id": scene_id})


func _on_scenario_reloaded(scene_id: String) -> void:
	_trigger("scenario_reloaded", {"scene_id": scene_id})


func _trigger(event_id: String, payload: Dictionary) -> void:
	var event_manager: Node = _find_system(EVENT_MANAGER_GROUP)
	_call_if_supported(event_manager, "trigger_event", [event_id, payload])
