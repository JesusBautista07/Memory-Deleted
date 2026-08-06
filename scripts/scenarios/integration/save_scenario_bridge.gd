class_name SaveScenarioBridge
extends ScenarioIntegrationBridge

## Ticket 013C — Integración del Sistema de Guardado con el Sistema
## de Escenarios.
##
## SaveManager (save_manager.gd) está documentado para registrarse
## como Autoload con el nombre "SaveManager", y su propio comentario
## describe auto_save() como pensado para "puntos de control internos
## del propio flujo del juego (p. ej. al entrar a una nueva zona)".
## Este bridge cubre exactamente ese punto de control: al cargar
## correctamente un escenario, dispara un auto_save usando la API
## pública ya existente de SaveManager (auto_save/capture_game_state
## por dentro de auto_save). No se edita save_manager.gd.
##
## SaveManager se localiza primero como Autoload ("/root/SaveManager")
## y, si todavía no está registrado como tal, como respaldo por grupo
## ("save_manager"). Si no se encuentra de ninguna forma, este bridge
## simplemente no hace nada: nunca asume que SaveManager existe.

const SAVE_MANAGER_GROUP: String = "save_manager"
const SAVE_MANAGER_AUTOLOAD_PATH: NodePath = ^"/root/SaveManager"

## Permite desactivar el auto-guardado al entrar a un escenario sin
## tener que quitar el nodo de la escena.
@export var auto_save_on_scenario_loaded: bool = true


func _on_scenario_loaded(_scene_id: String, _data: SceneData) -> void:
	if not auto_save_on_scenario_loaded:
		return

	var save_manager: Node = _find_save_manager()
	if save_manager == null or not save_manager.has_method("auto_save"):
		return

	_call_if_supported(save_manager, "auto_save", [SaveData.new()])


func _find_save_manager() -> Node:
	var autoload: Node = get_node_or_null(SAVE_MANAGER_AUTOLOAD_PATH)
	if autoload != null:
		return autoload
	return _find_system(SAVE_MANAGER_GROUP)
