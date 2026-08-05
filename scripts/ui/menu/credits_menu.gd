extends Control
## Pantalla de créditos con desplazamiento vertical (ScrollContainer
## en la escena). Sin lógica adicional.

signal closed

@onready var _button_close: Button = %ButtonClose


func _ready() -> void:
	_button_close.pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	closed.emit()
