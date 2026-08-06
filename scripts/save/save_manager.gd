extends Node

## Núcleo del Sistema de Guardado.
## Gestiona creación, guardado, carga, sobrescritura y eliminación de
## partidas, usando Resource + FileAccess/ResourceSaver.
##
## Pensado para registrarse como Autoload con el nombre "SaveManager".
## No conoce ninguna clase concreta del resto del juego (Player,
## Inventory, Objects, Documents, Doors, Events, Puzzles): localiza a
## sus representantes en la escena por grupo y les habla por contrato
## (duck typing vía has_method), evitando dependencias directas.

signal game_saved(slot_id: int)
signal game_loaded(slot_id: int)
signal save_deleted(slot_id: int)
signal save_error(operation: String, message: String)

const SAVE_DIRECTORY: String = "user://saves/"
const SAVE_EXTENSION: String = ".tres"
const BACKUP_EXTENSION: String = ".bak"
const TEMP_EXTENSION: String = ".tmp"
const MAX_SLOTS: int = 10

# Versión actual del formato de SaveData. Toda partida guardada queda
# marcada con este valor; al cargar una partida con una versión distinta
# se invoca _migrate_save_data() para prepararla (soporte de ampliaciones
# futuras sin romper compatibilidad con partidas ya existentes).
const SAVE_FORMAT_VERSION: int = 1

# Ranuras reservadas (no forman parte de las MAX_SLOTS ranuras numeradas).
const QUICK_SAVE_SLOT: int = -1
const AUTO_SAVE_SLOT: int = -2
const CHECKPOINT_SLOT: int = -3

# ------------------------------------------------------------
# Grupos de integración con el resto del juego.
#
# Contrato esperado por grupo:
#   GROUP_PLAYER      -> nodo Node3D (posición/rotación se leen directamente)
#   GROUP_LEVEL       -> get_level_name() -> String  (opcional; si no existe
#                        ningún nodo en este grupo, se deriva del nombre de
#                        archivo de la escena actual)
#   GROUP_INVENTORY   -> save_state() -> Dictionary / load_state(Dictionary)
#   GROUP_DOCUMENTS   -> get_read_documents() -> Array / load_read_documents(Array)
#   GROUP_OBJECTS     -> get_save_id() -> String
#                        get_save_state() -> Dictionary
#                        apply_save_state(Dictionary) -> void
#   GROUP_DOORS       -> mismo contrato que GROUP_OBJECTS
#   GROUP_EVENTS      -> mismo contrato que GROUP_OBJECTS
#   GROUP_PUZZLES     -> mismo contrato que GROUP_OBJECTS
# ------------------------------------------------------------
const GROUP_PLAYER: String = "saveable_player"
const GROUP_LEVEL: String = "saveable_level"
const GROUP_INVENTORY: String = "saveable_inventory"
const GROUP_OBJECTS: String = "saveable_objects"
const GROUP_DOCUMENTS: String = "saveable_documents"
const GROUP_DOORS: String = "saveable_doors"
const GROUP_EVENTS: String = "saveable_events"
const GROUP_PUZZLES: String = "saveable_puzzles"


func _ready() -> void:
	_ensure_save_directory()


# ============================================================
# DIRECTORIO Y RUTAS
# ============================================================

func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(SAVE_DIRECTORY)


func _get_slot_file_name(slot_id: int) -> String:
	match slot_id:
		QUICK_SAVE_SLOT:
			return "quicksave%s" % SAVE_EXTENSION
		AUTO_SAVE_SLOT:
			return "autosave%s" % SAVE_EXTENSION
		CHECKPOINT_SLOT:
			return "checkpoint%s" % SAVE_EXTENSION
		_:
			return "slot_%d%s" % [slot_id, SAVE_EXTENSION]


func _get_save_path(slot_id: int) -> String:
	return SAVE_DIRECTORY + _get_slot_file_name(slot_id)


func _delete_file_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


# ============================================================
# CREACIÓN / GUARDADO / CARGA
# ============================================================

## Crea una nueva partida vacía para la ranura indicada, lista para ser
## rellenada por los sistemas del juego antes de guardarla.
func create_new_game(slot_id: int) -> SaveData:
	var data := SaveData.new()
	data.slot_id = slot_id
	data.save_name = "Partida %d" % slot_id
	data.save_version = SAVE_FORMAT_VERSION
	_stamp_datetime(data)
	return data


## Guarda una partida nueva en la ranura indicada.
## Falla si la ranura ya contiene una partida (usar overwrite_game()).
func save_game(slot_id: int, data: SaveData) -> bool:
	if slot_exists(slot_id):
		push_warning("SaveManager: la ranura %d ya existe. Usa overwrite_game()." % slot_id)
		save_error.emit("save_game", "La ranura %d ya existe." % slot_id)
		return false
	return _write_save(slot_id, data)


## Sobrescribe una partida existente en la ranura indicada (o la crea si no existe).
func overwrite_game(slot_id: int, data: SaveData) -> bool:
	return _write_save(slot_id, data)


## Escritura atómica y a prueba de corrupción:
## 1) Se guarda en un archivo temporal (.tmp).
## 2) Se valida ese archivo temporal releyéndolo.
## 3) Solo si es válido, la partida anterior (si existe) se conserva como
##    copia de seguridad (.bak) y el temporal reemplaza al archivo final.
## Si el juego se cierra o falla a mitad de este proceso, el archivo de
## guardado real nunca queda a medio escribir.
func _write_save(slot_id: int, data: SaveData) -> bool:
	_ensure_save_directory()
	data.slot_id = slot_id
	data.save_version = SAVE_FORMAT_VERSION
	_stamp_datetime(data)

	var file_name := _get_slot_file_name(slot_id)
	var temp_name := file_name + TEMP_EXTENSION
	var backup_name := file_name + BACKUP_EXTENSION
	var path := SAVE_DIRECTORY + file_name
	var temp_path := SAVE_DIRECTORY + temp_name

	var err := ResourceSaver.save(data, temp_path)
	if err != OK:
		save_error.emit("save_game", "Error al guardar la ranura %d (código %d)." % [slot_id, err])
		_delete_file_if_exists(temp_path)
		return false

	var validation := _try_load_save_data(temp_path)
	if not validation.ok:
		save_error.emit("save_game", "El guardado generado no superó la validación: %s" % validation.error)
		_delete_file_if_exists(temp_path)
		return false

	var dir := DirAccess.open(SAVE_DIRECTORY)
	if dir == null:
		save_error.emit("save_game", "No se pudo acceder al directorio de guardado.")
		_delete_file_if_exists(temp_path)
		return false

	if FileAccess.file_exists(path):
		_delete_file_if_exists(SAVE_DIRECTORY + backup_name)
		dir.rename(file_name, backup_name)

	var rename_err := dir.rename(temp_name, file_name)
	if rename_err != OK:
		save_error.emit("save_game", "Error al finalizar el guardado de la ranura %d (código %d)." % [slot_id, rename_err])
		return false

	game_saved.emit(slot_id)
	return true


## Carga la partida almacenada en la ranura indicada, validándola antes de
## entregarla. Si el archivo está corrupto y existe una copia de
## seguridad válida, se recupera automáticamente desde ella.
func load_game(slot_id: int) -> SaveData:
	var path := _get_save_path(slot_id)
	var result := _try_load_save_data(path)
	if result.ok:
		game_loaded.emit(slot_id)
		return result.data as SaveData

	save_error.emit("load_game", result.error)

	var backup_path := path + BACKUP_EXTENSION
	if FileAccess.file_exists(backup_path):
		var backup_result := _try_load_save_data(backup_path)
		if backup_result.ok:
			push_warning("SaveManager: ranura %d dañada; recuperada desde copia de seguridad." % slot_id)
			save_error.emit("load_game", "Ranura %d recuperada desde copia de seguridad." % slot_id)
			game_loaded.emit(slot_id)
			return backup_result.data as SaveData

	return null


## Elimina la partida de la ranura indicada, junto con cualquier copia de
## seguridad o archivo temporal asociado.
func delete_save(slot_id: int) -> bool:
	var path := _get_save_path(slot_id)
	if not FileAccess.file_exists(path):
		save_error.emit("delete_save", "No existe partida en la ranura %d." % slot_id)
		return false

	var dir := DirAccess.open(SAVE_DIRECTORY)
	if dir == null:
		save_error.emit("delete_save", "No se pudo acceder al directorio de guardado.")
		return false

	var file_name := _get_slot_file_name(slot_id)
	var err := dir.remove(file_name)
	if err != OK:
		save_error.emit("delete_save", "Error al eliminar la ranura %d (código %d)." % [slot_id, err])
		return false

	_delete_file_if_exists(SAVE_DIRECTORY + file_name + BACKUP_EXTENSION)
	_delete_file_if_exists(SAVE_DIRECTORY + file_name + TEMP_EXTENSION)

	save_deleted.emit(slot_id)
	return true


func _stamp_datetime(data: SaveData) -> void:
	var dt := Time.get_datetime_dict_from_system()
	data.save_date = "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]
	data.save_time = "%02d:%02d:%02d" % [dt.hour, dt.minute, dt.second]


# ============================================================
# VALIDACIÓN DE ARCHIVOS Y VERSIONADO
# ============================================================

## Intenta leer y validar un SaveData desde disco sin lanzar excepciones.
## Devuelve {ok: bool, data: SaveData, error: String}. No emite señales:
## es responsabilidad de quien llama decidir qué hacer con el resultado.
func _try_load_save_data(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "data": null, "error": "El archivo no existe: %s" % path}
	if not path.ends_with(SAVE_EXTENSION) and not path.ends_with(SAVE_EXTENSION + TEMP_EXTENSION):
		return {"ok": false, "data": null, "error": "Extensión de archivo no soportada: %s" % path}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "data": null, "error": "No se pudo abrir el archivo (código %d)." % FileAccess.get_open_error()}
	file.close()

	var resource: Resource = ResourceLoader.load(path, "SaveData", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null or not (resource is SaveData):
		return {"ok": false, "data": null, "error": "El archivo está corrupto o no es un SaveData válido: %s" % path}

	var data := resource as SaveData
	if data.save_version > SAVE_FORMAT_VERSION:
		return {
			"ok": false,
			"data": null,
			"error": "La partida usa una versión (%d) más reciente que la soportada (%d)." % [data.save_version, SAVE_FORMAT_VERSION],
		}

	_migrate_save_data(data)
	return {"ok": true, "data": data, "error": ""}


## Punto único de migración de partidas antiguas a la versión actual.
## Se ejecuta automáticamente al validar cualquier partida. Sin casos
## definidos todavía: se irán añadiendo a medida que SaveData evolucione,
## sin romper la carga de partidas guardadas con versiones anteriores.
func _migrate_save_data(data: SaveData) -> void:
	if data.save_version == SAVE_FORMAT_VERSION:
		return
	push_warning("SaveManager: migrando SaveData de la versión %d a %d." % [data.save_version, SAVE_FORMAT_VERSION])
	data.save_version = SAVE_FORMAT_VERSION


# ============================================================
# CONSULTA DE RANURAS
# ============================================================

## Verifica si existe una partida guardada en la ranura indicada.
func slot_exists(slot_id: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot_id))


## Devuelve la información resumida (SaveSlot) de una ranura, exista,
## esté vacía o esté corrupta (en cuyo caso se comporta como vacía).
func get_slot_info(slot_id: int) -> SaveSlot:
	var path := _get_save_path(slot_id)
	if not slot_exists(slot_id):
		return SaveSlot.empty(slot_id, path)

	var data := load_game(slot_id)
	if data == null:
		return SaveSlot.empty(slot_id, path)

	return SaveSlot.from_save_data(slot_id, path, data)


## Devuelve la información resumida de todas las ranuras numeradas (0 a MAX_SLOTS - 1).
func get_all_slots() -> Array[SaveSlot]:
	var slots: Array[SaveSlot] = []
	for i in range(MAX_SLOTS):
		slots.append(get_slot_info(i))
	return slots


func get_quick_save_info() -> SaveSlot:
	return get_slot_info(QUICK_SAVE_SLOT)


func get_auto_save_info() -> SaveSlot:
	return get_slot_info(AUTO_SAVE_SLOT)


func get_checkpoint_info() -> SaveSlot:
	return get_slot_info(CHECKPOINT_SLOT)


# ============================================================
# INTEGRACIÓN CON LOS SISTEMAS DEL JUEGO
# ============================================================
# El SaveManager solo conoce grupos y un contrato de métodos (ver
# constantes GROUP_*). No importa ni referencia ninguna clase concreta.

## Recoge el estado actual de todos los sistemas guardables presentes en
## la escena y lo vuelca en el SaveData indicado. Llamar justo antes de
## save_game() / overwrite_game() (o usar los wrappers save_current_game()
## / overwrite_current_game() más abajo).
func capture_game_state(data: SaveData) -> void:
	_capture_level_info(data)
	_capture_player(data)
	_capture_inventory(data)
	_capture_documents(data)
	_capture_id_based(data.objects_state, GROUP_OBJECTS)
	_capture_id_based(data.doors_state, GROUP_DOORS)
	_capture_id_based(data.events_state, GROUP_EVENTS)
	_capture_id_based(data.puzzles_state, GROUP_PUZZLES)


## Aplica el estado contenido en el SaveData indicado a los sistemas
## guardables presentes en la escena actual. Llamar una vez la escena de
## destino esté cargada (o usar load_and_apply_game() más abajo).
func apply_game_state(data: SaveData) -> void:
	_apply_player(data)
	_apply_inventory(data)
	_apply_documents(data)
	_apply_id_based(data.objects_state, GROUP_OBJECTS)
	_apply_id_based(data.doors_state, GROUP_DOORS)
	_apply_id_based(data.events_state, GROUP_EVENTS)
	_apply_id_based(data.puzzles_state, GROUP_PUZZLES)


func _capture_level_info(data: SaveData) -> void:
	var current_scene_node := get_tree().current_scene
	if current_scene_node != null:
		data.current_scene = current_scene_node.scene_file_path

	var level_nodes := get_tree().get_nodes_in_group(GROUP_LEVEL)
	if not level_nodes.is_empty() and level_nodes[0].has_method("get_level_name"):
		data.level_name = level_nodes[0].get_level_name()
	elif not data.current_scene.is_empty():
		data.level_name = data.current_scene.get_file().get_basename()


func _capture_player(data: SaveData) -> void:
	var players := get_tree().get_nodes_in_group(GROUP_PLAYER)
	if players.is_empty():
		return
	var player := players[0]
	if player is Node3D:
		var player_3d := player as Node3D
		data.player_position = player_3d.global_position
		data.player_rotation = player_3d.rotation


func _apply_player(data: SaveData) -> void:
	var players := get_tree().get_nodes_in_group(GROUP_PLAYER)
	if players.is_empty():
		return
	var player := players[0]
	if player is Node3D:
		var player_3d := player as Node3D
		player_3d.global_position = data.player_position
		player_3d.rotation = data.player_rotation


func _capture_inventory(data: SaveData) -> void:
	var nodes := get_tree().get_nodes_in_group(GROUP_INVENTORY)
	if nodes.is_empty():
		return
	var inventory_node := nodes[0]
	if inventory_node.has_method("save_state"):
		data.inventory = inventory_node.save_state()


func _apply_inventory(data: SaveData) -> void:
	var nodes := get_tree().get_nodes_in_group(GROUP_INVENTORY)
	if nodes.is_empty():
		return
	var inventory_node := nodes[0]
	if inventory_node.has_method("load_state"):
		inventory_node.load_state(data.inventory)


func _capture_documents(data: SaveData) -> void:
	var nodes := get_tree().get_nodes_in_group(GROUP_DOCUMENTS)
	if nodes.is_empty():
		return
	var documents_node := nodes[0]
	if documents_node.has_method("get_read_documents"):
		data.documents = documents_node.get_read_documents()


func _apply_documents(data: SaveData) -> void:
	var nodes := get_tree().get_nodes_in_group(GROUP_DOCUMENTS)
	if nodes.is_empty():
		return
	var documents_node := nodes[0]
	if documents_node.has_method("load_read_documents"):
		documents_node.load_read_documents(data.documents)


## Recoge el estado de cada nodo guardable de un grupo (identificado por
## get_save_id()) y lo escribe en target_state. target_state debe ser uno
## de los Dictionary de SaveData (objects_state, doors_state, events_state,
## puzzles_state); al ser un tipo por referencia, se modifica en el sitio.
func _capture_id_based(target_state: Dictionary, group_name: String) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		if not (node.has_method("get_save_id") and node.has_method("get_save_state")):
			continue
		var save_id: String = node.get_save_id()
		if save_id.is_empty():
			continue
		target_state[save_id] = node.get_save_state()


## Aplica el estado guardado en target_state a los nodos guardables
## actualmente presentes en group_name, emparejándolos por get_save_id().
## Un nodo sin entrada en target_state conserva su estado por defecto.
func _apply_id_based(target_state: Dictionary, group_name: String) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		if not (node.has_method("get_save_id") and node.has_method("apply_save_state")):
			continue
		var save_id: String = node.get_save_id()
		if not target_state.has(save_id):
			continue
		node.apply_save_state(target_state[save_id])


# ============================================================
# WRAPPERS DE CONVENIENCIA (captura/aplicación + persistencia)
# ============================================================

## Recoge el estado actual del juego y guarda una partida nueva en slot_id.
func save_current_game(slot_id: int, data: SaveData) -> bool:
	capture_game_state(data)
	return save_game(slot_id, data)


## Recoge el estado actual del juego y sobrescribe la partida en slot_id.
func overwrite_current_game(slot_id: int, data: SaveData) -> bool:
	capture_game_state(data)
	return overwrite_game(slot_id, data)


## Carga slot_id y aplica su estado a los sistemas presentes en el árbol.
## Llamar una vez la escena de destino esté completamente cargada.
func load_and_apply_game(slot_id: int) -> SaveData:
	var data := load_game(slot_id)
	if data != null:
		apply_game_state(data)
	return data


# ============================================================
# QUICK SAVE / QUICK LOAD
# ============================================================

## Guardado rápido en la ranura reservada QUICK_SAVE_SLOT. Recoge
## automáticamente el estado actual de los sistemas del juego.
func quick_save(data: SaveData) -> bool:
	capture_game_state(data)
	data.save_name = "Quick Save"
	return overwrite_game(QUICK_SAVE_SLOT, data)


## Carga el guardado rápido y aplica su estado a la escena actual.
func quick_load() -> SaveData:
	if not slot_exists(QUICK_SAVE_SLOT):
		save_error.emit("quick_load", "No existe ningún Quick Save.")
		return null
	var data := load_game(QUICK_SAVE_SLOT)
	if data != null:
		apply_game_state(data)
	return data


func has_quick_save() -> bool:
	return slot_exists(QUICK_SAVE_SLOT)


# ============================================================
# AUTO SAVE
# ============================================================

## Ejecuta un guardado automático en la ranura reservada AUTO_SAVE_SLOT.
## Pensado para ser llamado periódicamente o en puntos de control internos
## del propio flujo del juego (p. ej. al entrar a una nueva zona).
func auto_save(data: SaveData) -> bool:
	capture_game_state(data)
	data.save_name = "Auto Save"
	return overwrite_game(AUTO_SAVE_SLOT, data)


## Carga el Auto Save y aplica su estado a la escena actual.
func auto_load() -> SaveData:
	if not slot_exists(AUTO_SAVE_SLOT):
		save_error.emit("auto_load", "No existe ningún Auto Save.")
		return null
	var data := load_game(AUTO_SAVE_SLOT)
	if data != null:
		apply_game_state(data)
	return data


func has_auto_save() -> bool:
	return slot_exists(AUTO_SAVE_SLOT)


# ============================================================
# CHECKPOINTS
# ============================================================

## Guarda un checkpoint en la ranura reservada CHECKPOINT_SLOT.
## Pensado para ser invocado por triggers/puntos de control del nivel.
func save_checkpoint(data: SaveData) -> bool:
	capture_game_state(data)
	data.save_name = "Checkpoint"
	return overwrite_game(CHECKPOINT_SLOT, data)


## Carga el último checkpoint y aplica su estado a la escena actual.
func load_checkpoint() -> SaveData:
	if not slot_exists(CHECKPOINT_SLOT):
		save_error.emit("load_checkpoint", "No existe ningún Checkpoint.")
		return null
	var data := load_game(CHECKPOINT_SLOT)
	if data != null:
		apply_game_state(data)
	return data


func has_checkpoint() -> bool:
	return slot_exists(CHECKPOINT_SLOT)
