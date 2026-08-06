class_name CinematicState
## Estados posibles de una cinemática.
##
## Clase estática de solo datos. No contiene lógica, no depende de ningún
## Manager ni de otro sistema. Únicamente define el vocabulario de estados
## que otras capas (ajenas a este módulo) podrán utilizar.

## La cinemática aún no ha sido inicializada / no existe información de ejecución.
const NONE: int = 0

## La cinemática fue solicitada pero todavía no comenzó a reproducirse.
const QUEUED: int = 1

## La cinemática está cargando sus recursos.
const LOADING: int = 2

## La cinemática se encuentra en reproducción.
const PLAYING: int = 3

## La cinemática está en pausa.
const PAUSED: int = 4

## La cinemática fue saltada (skip) por el usuario u otro medio externo.
const SKIPPED: int = 5

## La cinemática finalizó su reproducción de forma normal.
const FINISHED: int = 6

## La cinemática fue cancelada antes de finalizar.
const CANCELLED: int = 7

## La cinemática finalizó con un error.
const FAILED: int = 8

## Enum equivalente, disponible para tipado fuerte en Resources o parámetros.
enum State {
	NONE = 0,
	QUEUED = 1,
	LOADING = 2,
	PLAYING = 3,
	PAUSED = 4,
	SKIPPED = 5,
	FINISHED = 6,
	CANCELLED = 7,
	FAILED = 8,
}

## Devuelve el nombre legible de un estado (constante int o State).
## Utilidad de solo lectura, no ejecuta ni modifica ningún estado real.
static func get_state_name(state: int) -> String:
	match state:
		NONE:
			return "NONE"
		QUEUED:
			return "QUEUED"
		LOADING:
			return "LOADING"
		PLAYING:
			return "PLAYING"
		PAUSED:
			return "PAUSED"
		SKIPPED:
			return "SKIPPED"
		FINISHED:
			return "FINISHED"
		CANCELLED:
			return "CANCELLED"
		FAILED:
			return "FAILED"
		_:
			return "UNKNOWN"
