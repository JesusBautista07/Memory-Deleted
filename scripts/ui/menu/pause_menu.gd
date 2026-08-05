extends CanvasLayer
## Menú de pausa. Se abre/cierra con ui_cancel (ESC por defecto).
## Pausa el árbol de escena, muestra el cursor y bloquea el movimiento
## del jugador/cámara de forma indirecta (esos scripts dejan de procesar
## al pausar el árbol, sin necesidad de modificarlos).

@onready var _panel: Control = %Panel
@onready var _button_continue: Button = %ButtonContinue
@onready var _button_inventory: Button = %ButtonInventory
@onready var _button_settings: Button = %ButtonSettings
@onready var _button_main_menu: Button = %ButtonMainMenu
@onready var _button_quit: Button = %ButtonQuit
@onready var _inventory_ui: Control = %InventoryUI
@onready var _options_menu: Control = %OptionsMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_button_continue.pressed.connect(_on_continue_pressed)
	_button_inventory.pressed.connect(_on_inventory_pressed)
	_button_settings.pressed.connect(_on_settings_pressed)
	_button_main_menu.pressed.connect(_on_main_menu_pressed)
	_button_quit.pressed.connect(_on_quit_pressed)

	_inventory_ui.visible = false
	_options_menu.visible = false
	_inventory_ui.closed.connect(_on_inventory_closed)
	_options_menu.closed.connect(_on_options_closed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	if visible:
		_close_pause()
	else:
		_open_pause()


func _open_pause() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_pause() -> void:
	visible = false
	_inventory_ui.visible = false
	_options_menu.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_continue_pressed() -> void:
	_close_pause()


func _on_inventory_pressed() -> void:
	_inventory_ui.visible = true


func _on_settings_pressed() -> void:
	_options_menu.visible = true


func _on_inventory_closed() -> void:
	_inventory_ui.visible = false


func _on_options_closed() -> void:
	_options_menu.visible = false


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/menu/MainMenu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
