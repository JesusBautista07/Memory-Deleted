extends Control
## Pantalla de carga. Sin lógica de carga real: solo expone
## set_progress()/set_loading_text() para que el sistema que
## dispare la carga la controle.

@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _loading_label: Label = %LoadingLabel


func _ready() -> void:
	_progress_bar.value = 0
	_loading_label.text = "Cargando..."


func set_progress(value: float) -> void:
	_progress_bar.value = clamp(value, 0.0, 100.0)


func set_loading_text(text: String) -> void:
	_loading_label.text = text
