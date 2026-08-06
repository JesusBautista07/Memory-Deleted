class_name UIScenarioBridge
extends ScenarioIntegrationBridge

## Ticket 013C — Integración de la UI con el Sistema de Escenarios.
##
## Muestra/oculta la pantalla de carga (LoadingScreen) durante las
## transiciones de escenario, usando únicamente la API pública que
## LoadingScreen ya expone. Su propio comentario de cabecera lo deja
## explícito: "Sin lógica de carga real: solo expone
## set_progress()/set_loading_text() para que el sistema que dispare
## la carga la controle" (ver loading_screen.gd). Este bridge es
## precisamente ese sistema externo.
##
## LoadingScreen se localiza por el grupo "loading_screen",
## pertenencia que se asigna en la escena (mismo patrón que el resto
## de grupos del proyecto). No se edita loading_screen.gd.

const LOADING_SCREEN_GROUP: String = "loading_screen"
const LOADING_TEXT: String = "Cargando..."


func _on_scenario_load_started(_scene_id: String) -> void:
	_set_loading_visible(true, LOADING_TEXT)


func _on_scenario_loaded(_scene_id: String, _data: SceneData) -> void:
	_set_loading_visible(false)


func _on_scenario_load_failed(_scene_id: String, _error: String) -> void:
	_set_loading_visible(false)


func _on_scenario_unload_started(_scene_id: String) -> void:
	_set_loading_visible(true, LOADING_TEXT)


func _set_loading_visible(visible_state: bool, text: String = "") -> void:
	var loading_screen: CanvasItem = _find_system(LOADING_SCREEN_GROUP) as CanvasItem
	if loading_screen == null:
		return

	loading_screen.visible = visible_state
	if visible_state and not text.is_empty():
		_call_if_supported(loading_screen, "set_loading_text", [text])
