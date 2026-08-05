extends Control
## Menú de ajustes: Controles, Mouse, Video y Audio.
## Aplica cambios directamente sobre motor/servidores cuando es seguro
## (no depende de otros sistemas del proyecto). Los buses de audio
## Music/SFX/Ambience/Voices pueden no existir todavía: si no existen,
## el valor se ignora en tiempo real pero no produce error.

signal closed
signal quality_changed(preset: String)
signal brightness_changed(value: float)

const REBINDABLE_ACTIONS: Array[Dictionary] = [
	{"action": "move_forward", "label": "Mover adelante"},
	{"action": "move_back", "label": "Mover atrás"},
	{"action": "move_left", "label": "Mover izquierda"},
	{"action": "move_right", "label": "Mover derecha"},
	{"action": "sprint", "label": "Correr"},
	{"action": "jump", "label": "Saltar"},
	{"action": "crouch", "label": "Agacharse"},
	{"action": "interact", "label": "Interactuar"},
	{"action": "inventory", "label": "Inventario"},
	{"action": "ui_cancel", "label": "Pausa"},
]

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

const FPS_LIMITS: Array[int] = [0, 30, 60, 90, 120, 144, 240]
const QUALITY_PRESETS: Array[String] = ["Baja", "Media", "Alta", "Ultra"]
const AUDIO_BUSES: Dictionary = {
	"master": "Master",
	"music": "Music",
	"sfx": "SFX",
	"ambience": "Ambience",
	"voices": "Voices",
}

@onready var _button_close: Button = %ButtonClose
@onready var _controls_list: VBoxContainer = %ControlsList
@onready var _sensitivity_slider: HSlider = %SensitivitySlider
@onready var _invert_y_checkbox: CheckBox = %InvertYCheckBox
@onready var _fullscreen_checkbox: CheckBox = %FullscreenCheckBox
@onready var _resolution_option: OptionButton = %ResolutionOption
@onready var _vsync_checkbox: CheckBox = %VSyncCheckBox
@onready var _fps_limit_option: OptionButton = %FPSLimitOption
@onready var _quality_option: OptionButton = %QualityOption
@onready var _fov_slider: HSlider = %FOVSlider
@onready var _brightness_slider: HSlider = %BrightnessSlider
@onready var _master_volume_slider: HSlider = %MasterVolumeSlider
@onready var _music_volume_slider: HSlider = %MusicVolumeSlider
@onready var _sfx_volume_slider: HSlider = %SFXVolumeSlider
@onready var _ambience_volume_slider: HSlider = %AmbienceVolumeSlider
@onready var _voices_volume_slider: HSlider = %VoicesVolumeSlider
@onready var _reset_defaults_button: Button = %ResetDefaultsButton

var _listening_action: String = ""
var _action_buttons: Dictionary = {}


func _ready() -> void:
	_button_close.pressed.connect(_on_close_pressed)
	_build_controls_tab()
	_setup_mouse_tab()
	_setup_video_tab()
	_setup_audio_tab()
	_reset_defaults_button.pressed.connect(_on_reset_defaults_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if _listening_action.is_empty():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		_assign_key(_listening_action, event)
		get_viewport().set_input_as_handled()


func _build_controls_tab() -> void:
	for entry in REBINDABLE_ACTIONS:
		var action: String = entry["action"]
		var label_text: String = entry["label"]

		if not InputMap.has_action(action):
			InputMap.add_action(action)

		var row := HBoxContainer.new()

		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size = Vector2(180, 0)
		row.add_child(label)

		var key_button := Button.new()
		key_button.custom_minimum_size = Vector2(160, 0)
		key_button.text = _get_key_display(action)
		key_button.pressed.connect(_on_rebind_button_pressed.bind(action, key_button))
		row.add_child(key_button)

		_controls_list.add_child(row)
		_action_buttons[action] = key_button


func _on_rebind_button_pressed(action: String, button: Button) -> void:
	_listening_action = action
	button.text = "Presiona una tecla..."


func _assign_key(action: String, event: InputEventKey) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	if _action_buttons.has(action):
		_action_buttons[action].text = _get_key_display(action)
	_listening_action = ""


func _get_key_display(action: String) -> String:
	var events := InputMap.action_get_events(action)
	for e in events:
		if e is InputEventKey:
			return OS.get_keycode_string(e.physical_keycode)
	return "Sin asignar"


func _setup_mouse_tab() -> void:
	_sensitivity_slider.min_value = 0.01
	_sensitivity_slider.max_value = 1.0
	_sensitivity_slider.step = 0.01
	_sensitivity_slider.value = 0.15
	_invert_y_checkbox.button_pressed = false


func _setup_video_tab() -> void:
	_fullscreen_checkbox.button_pressed = false
	_fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)

	_resolution_option.clear()
	for res in RESOLUTIONS:
		_resolution_option.add_item("%dx%d" % [res.x, res.y])
	_resolution_option.selected = 2
	_resolution_option.item_selected.connect(_on_resolution_selected)

	_vsync_checkbox.button_pressed = true
	_vsync_checkbox.toggled.connect(_on_vsync_toggled)

	_fps_limit_option.clear()
	for limit in FPS_LIMITS:
		_fps_limit_option.add_item("Sin límite" if limit == 0 else str(limit))
	_fps_limit_option.selected = 0
	_fps_limit_option.item_selected.connect(_on_fps_limit_selected)

	_quality_option.clear()
	for preset in QUALITY_PRESETS:
		_quality_option.add_item(preset)
	_quality_option.selected = 2
	_quality_option.item_selected.connect(_on_quality_selected)

	_fov_slider.min_value = 60.0
	_fov_slider.max_value = 110.0
	_fov_slider.step = 1.0
	_fov_slider.value = 75.0
	_fov_slider.value_changed.connect(_on_fov_changed)

	_brightness_slider.min_value = 0.1
	_brightness_slider.max_value = 2.0
	_brightness_slider.step = 0.05
	_brightness_slider.value = 1.0
	_brightness_slider.value_changed.connect(_on_brightness_changed)


func _on_fullscreen_toggled(pressed: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func _on_resolution_selected(index: int) -> void:
	if index < 0 or index >= RESOLUTIONS.size():
		return
	DisplayServer.window_set_size(RESOLUTIONS[index])


func _on_vsync_toggled(pressed: bool) -> void:
	var mode := DisplayServer.VSYNC_ENABLED if pressed else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)


func _on_fps_limit_selected(index: int) -> void:
	if index < 0 or index >= FPS_LIMITS.size():
		return
	Engine.max_fps = FPS_LIMITS[index]


func _on_quality_selected(index: int) -> void:
	if index < 0 or index >= QUALITY_PRESETS.size():
		return
	quality_changed.emit(QUALITY_PRESETS[index])


func _on_fov_changed(value: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		camera.fov = value


func _on_brightness_changed(value: float) -> void:
	brightness_changed.emit(value)


func _setup_audio_tab() -> void:
	_master_volume_slider.min_value = 0.0
	_master_volume_slider.max_value = 100.0
	_master_volume_slider.value = 100.0
	_master_volume_slider.value_changed.connect(_on_master_volume_changed)

	_music_volume_slider.min_value = 0.0
	_music_volume_slider.max_value = 100.0
	_music_volume_slider.value = 100.0
	_music_volume_slider.value_changed.connect(_on_music_volume_changed)

	_sfx_volume_slider.min_value = 0.0
	_sfx_volume_slider.max_value = 100.0
	_sfx_volume_slider.value = 100.0
	_sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)

	_ambience_volume_slider.min_value = 0.0
	_ambience_volume_slider.max_value = 100.0
	_ambience_volume_slider.value = 100.0
	_ambience_volume_slider.value_changed.connect(_on_ambience_volume_changed)

	_voices_volume_slider.min_value = 0.0
	_voices_volume_slider.max_value = 100.0
	_voices_volume_slider.value = 100.0
	_voices_volume_slider.value_changed.connect(_on_voices_volume_changed)


func _on_master_volume_changed(value: float) -> void:
	_apply_bus_volume(AUDIO_BUSES["master"], value)


func _on_music_volume_changed(value: float) -> void:
	_apply_bus_volume(AUDIO_BUSES["music"], value)


func _on_sfx_volume_changed(value: float) -> void:
	_apply_bus_volume(AUDIO_BUSES["sfx"], value)


func _on_ambience_volume_changed(value: float) -> void:
	_apply_bus_volume(AUDIO_BUSES["ambience"], value)


func _on_voices_volume_changed(value: float) -> void:
	_apply_bus_volume(AUDIO_BUSES["voices"], value)


func _apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var db := -80.0 if value <= 0.0 else linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(bus_index, db)


func _on_reset_defaults_pressed() -> void:
	_sensitivity_slider.value = 0.15
	_invert_y_checkbox.button_pressed = false

	_fullscreen_checkbox.button_pressed = false
	_on_fullscreen_toggled(false)

	_resolution_option.selected = 2
	_on_resolution_selected(2)

	_vsync_checkbox.button_pressed = true
	_on_vsync_toggled(true)

	_fps_limit_option.selected = 0
	_on_fps_limit_selected(0)

	_quality_option.selected = 2
	_on_quality_selected(2)

	_fov_slider.value = 75.0
	_on_fov_changed(75.0)

	_brightness_slider.value = 1.0
	_on_brightness_changed(1.0)

	_master_volume_slider.value = 100.0
	_music_volume_slider.value = 100.0
	_sfx_volume_slider.value = 100.0
	_ambience_volume_slider.value = 100.0
	_voices_volume_slider.value = 100.0
	for bus_name in AUDIO_BUSES.values():
		_apply_bus_volume(bus_name, 100.0)


func _on_close_pressed() -> void:
	closed.emit()
