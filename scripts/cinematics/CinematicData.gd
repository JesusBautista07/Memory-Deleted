class_name CinematicData
extends Resource
## Contenedor puro de datos de una cinemática.
##
## Es un Resource: solo almacena información, no ejecuta lógica, no
## reproduce nada y no depende de ningún otro sistema o Manager.
## Pensado para ser creado como archivo .tres/.res y consumido por
## sistemas externos a este módulo.

## Identificador único de la cinemática (usado para buscarla/referenciarla).
@export var cinematic_id: StringName = &""

## Nombre legible de la cinemática (para editor, debug o UI).
@export var display_name: String = ""

## Descripción u observaciones libres sobre la cinemática.
@export_multiline var description: String = ""

## Ruta a la escena que representa la cinemática (no se instancia aquí).
@export_file("*.tscn") var scene_path: String = ""

## Ruta a un recurso de video, si la cinemática es un video pre-renderizado.
@export_file("*.ogv", "*.mp4", "*.webm") var video_path: String = ""

## Duración estimada/definida de la cinemática, en segundos.
@export var duration: float = 0.0

## Indica si la cinemática puede ser saltada (skip) por el jugador.
@export var is_skippable: bool = true

## Indica si la cinemática debe reproducirse una única vez por partida/perfil.
@export var is_one_shot: bool = false

## Prioridad relativa de la cinemática (uso libre para quien la consuma).
@export var priority: int = 0

## Etiquetas libres para clasificar/filtrar cinemáticas (ej: "intro", "boss").
@export var tags: PackedStringArray = PackedStringArray()

## Identificador de la pista de audio/música asociada, si aplica.
@export var audio_track_id: StringName = &""

## Datos adicionales de propósito genérico, para extensión futura sin
## romper compatibilidad (no se interpreta ni se valida en este módulo).
@export var metadata: Dictionary = {}
