extends Control
## Pequeño indicador de interacción ("Presiona E para..."). El texto
## se controla por código; no contiene lógica de interacción.

@onready var _label: Label = %PromptLabel


func _ready() -> void:
	visible = false


func show_prompt(text: String) -> void:
	_label.text = text
	visible = true


func hide_prompt() -> void:
	visible = false


func set_text(text: String) -> void:
	_label.text = text
