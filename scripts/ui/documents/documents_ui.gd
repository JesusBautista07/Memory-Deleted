extends Control
## Interfaz de lectura de documentos. Sin lógica de documentos:
## solo muestra los datos que le pasen por código.

signal closed

@onready var _title_label: Label = %TitleLabel
@onready var _content_label: RichTextLabel = %ContentLabel
@onready var _page_label: Label = %PageLabel
@onready var _button_close: Button = %ButtonClose


func _ready() -> void:
	_button_close.pressed.connect(_on_close_pressed)
	visible = false


func show_document(title: String, content: String, page: int = 1, total_pages: int = 1) -> void:
	_title_label.text = title
	_content_label.text = content
	_page_label.text = "Página %d/%d" % [page, total_pages]
	visible = true


func hide_document() -> void:
	visible = false


func _on_close_pressed() -> void:
	hide_document()
	closed.emit()
