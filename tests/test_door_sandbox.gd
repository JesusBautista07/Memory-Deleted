extends Node3D
## Script exclusivo de pruebas. Simula lo que hará el futuro sistema de
## Interacción (tecla de uso) y el futuro Inventario (array de llaves).
## NO forma parte del Sistema de Puertas.

@onready var door: Node3D = $Door

var player_keys: Array = []

func _ready() -> void:
	door.door_opened.connect(_on_door_opened)
	door.door_closed.connect(_on_door_closed)
	door.door_locked.connect(_on_door_locked)
	door.event_triggered.connect(_on_event_triggered)
	print("--- Test_Door listo. E = usar puerta | 1 = añadir llave correcta | 2 = añadir llave incorrecta | 0 = vaciar llaves ---")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_E:
				door.try_open(player_keys)
			KEY_1:
				player_keys.append("key_basement")
				print("Llave añadida: key_basement -> ", player_keys)
			KEY_2:
				player_keys.append("key_wrong")
				print("Llave añadida: key_wrong -> ", player_keys)
			KEY_0:
				player_keys.clear()
				print("Llaves reiniciadas -> ", player_keys)

func _on_door_opened() -> void:
	print("[SEÑAL] door_opened")

func _on_door_closed() -> void:
	print("[SEÑAL] door_closed")

func _on_door_locked(required_key: String) -> void:
	print("[SEÑAL] door_locked (requiere: ", required_key, ")")

func _on_event_triggered(event_name: String) -> void:
	print("[SEÑAL] event_triggered: ", event_name)
