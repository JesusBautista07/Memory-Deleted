extends Resource
class_name DocumentData

@export var document_id: String = ""
@export var title: String = ""
@export var pages: Array[String] = []
@export var page_images: Array[Texture2D] = []
@export_multiline var note: String = ""
@export var is_read: bool = false
@export var date_obtained: String = ""

func get_page_count() -> int:
	return pages.size()

func get_page_text(page_index: int) -> String:
	if page_index < 0 or page_index >= pages.size():
		return ""
	return pages[page_index]

func get_page_image(page_index: int) -> Texture2D:
	if page_index < 0 or page_index >= page_images.size():
		return null
	return page_images[page_index]
