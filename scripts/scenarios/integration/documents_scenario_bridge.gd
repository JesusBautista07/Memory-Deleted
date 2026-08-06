class_name DocumentsScenarioBridge
extends ScenarioIntegrationBridge

## Ticket 013C — Integración del Sistema de Documentos con el Sistema
## de Escenarios.
##
## Al empezar a descargar un escenario, o al cambiar de un escenario a
## otro, cierra cualquier documento que haya quedado abierto en
## DocumentManager, evitando que la UI de lectura quede visible sobre
## un escenario que ya no existe.
##
## DocumentManager se localiza por su propio grupo ya existente
## ("document_manager", const GROUP_NAME en document_manager.gd). Solo
## se usa su API pública ya existente
## (get_current_document/close_document). No se edita
## document_manager.gd.

const DOCUMENT_MANAGER_GROUP: String = "document_manager"


func _on_scenario_unload_started(_scene_id: String) -> void:
	_close_open_document()


func _on_scenario_changed(_previous_id: String, _new_id: String) -> void:
	_close_open_document()


func _close_open_document() -> void:
	var document_manager: Node = _find_system(DOCUMENT_MANAGER_GROUP)
	if document_manager == null:
		return

	if document_manager.has_method("get_current_document") \
			and document_manager.get_current_document() == null:
		return

	_call_if_supported(document_manager, "close_document")
