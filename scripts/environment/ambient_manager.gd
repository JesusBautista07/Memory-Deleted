class_name AmbientManager
extends Node

## Punto de entrada único del Sistema de Ambientación.
## Gestiona perfiles, transiciones y delega la aplicación real
## de valores a EnvironmentController.
##
## Se registra en el grupo "ambient_manager" para que otros sistemas
## (Eventos, Audio, Cinemáticas, Escenarios, Guardado) puedan
## localizarlo sin dependencias directas, siguiendo el mismo patrón
## usado por el resto de managers del proyecto.

signal profile_applied(profile_name: String)
signal profile_cleared
signal transition_started(profile_name: String, duration: float)
signal transition_finished(profile_name: String)

const GROUP_NAME: String = "ambient_manager"

var _profiles: Dictionary = {}
var _current_profile_name: String = ""
var _current_snapshot: Dictionary = {}
var _controller: EnvironmentController

var _tween: Tween


func _ready() -> void:
	add_to_group(GROUP_NAME)
	_controller = EnvironmentController.new()
	add_child(_controller)


# ---------------------------------------------------------------------------
# Registro de perfiles
# ---------------------------------------------------------------------------

func load_profile(profile_name: String, profile: EnvironmentProfile) -> void:
	# Registra (o reemplaza) un perfil bajo un nombre identificador.
	if profile == null:
		push_warning("AmbientManager: intento de registrar un perfil nulo (%s)" % profile_name)
		return
	_profiles[profile_name] = profile


func has_profile(profile_name: String) -> bool:
	return _profiles.has(profile_name)


func get_current_profile_name() -> String:
	return _current_profile_name


# ---------------------------------------------------------------------------
# Aplicación / limpieza de perfiles
# ---------------------------------------------------------------------------

func apply_profile(profile_name: String, transition_duration: float = -1.0, instant: bool = false) -> void:
	if not _profiles.has(profile_name):
		push_warning("AmbientManager: perfil no registrado '%s'" % profile_name)
		return

	var profile: EnvironmentProfile = _profiles[profile_name]
	var target_snapshot: Dictionary = profile.get_snapshot()
	var duration: float = transition_duration if transition_duration >= 0.0 else profile.default_transition_duration

	_current_profile_name = profile_name

	if instant or duration <= 0.0:
		_current_snapshot = target_snapshot
		_controller.apply_snapshot(_current_snapshot)
		profile_applied.emit(profile_name)
		transition_finished.emit(profile_name)
		return

	_run_transition(target_snapshot, duration, profile_name)


func clear_profile(transition_duration: float = -1.0) -> void:
	# Vuelve a un estado neutro: todo desactivado.
	var neutral_profile := EnvironmentProfile.new()
	var target_snapshot: Dictionary = neutral_profile.get_snapshot()
	var duration: float = transition_duration if transition_duration >= 0.0 else neutral_profile.default_transition_duration

	_current_profile_name = ""

	if duration <= 0.0:
		_current_snapshot = target_snapshot
		_controller.apply_snapshot(_current_snapshot)
		profile_cleared.emit()
		return

	_run_transition(target_snapshot, duration, "")
	profile_cleared.emit()


func blend_profiles(profile_a_name: String, profile_b_name: String, weight: float) -> void:
	# Mezcla instantánea de dos perfiles según weight [0.0 -> A, 1.0 -> B].
	# Útil para previsualización o para estados intermedios controlados
	# externamente (por ejemplo, por el futuro Sistema de Eventos).
	if not _profiles.has(profile_a_name) or not _profiles.has(profile_b_name):
		push_warning("AmbientManager: blend_profiles requiere dos perfiles registrados")
		return

	var snapshot_a: Dictionary = _profiles[profile_a_name].get_snapshot()
	var snapshot_b: Dictionary = _profiles[profile_b_name].get_snapshot()
	var blended: Dictionary = EnvironmentProfile.lerp_snapshot(snapshot_a, snapshot_b, clampf(weight, 0.0, 1.0))

	_current_snapshot = blended
	_controller.apply_snapshot(_current_snapshot)


func reload_environment() -> void:
	# Refresca las referencias del controlador (por ejemplo, tras cargar
	# una nueva escena) y reaplica el snapshot vigente.
	_controller.refresh_references()
	if not _current_snapshot.is_empty():
		_controller.apply_snapshot(_current_snapshot)


# ---------------------------------------------------------------------------
# Interruptores rápidos por categoría
# ---------------------------------------------------------------------------

func set_fog_enabled(enabled: bool) -> void:
	_controller.set_fog_master_enabled(enabled)
	_controller.apply_snapshot(_current_snapshot)


func set_rain_enabled(enabled: bool) -> void:
	_controller.set_rain_master_enabled(enabled)
	_controller.apply_snapshot(_current_snapshot)


func set_particles_enabled(enabled: bool) -> void:
	_controller.set_particles_master_enabled(enabled)
	_controller.apply_snapshot(_current_snapshot)


func set_postprocess_enabled(enabled: bool) -> void:
	_controller.set_postprocess_master_enabled(enabled)
	_controller.apply_snapshot(_current_snapshot)


# ---------------------------------------------------------------------------
# Transiciones internas
# ---------------------------------------------------------------------------

func _run_transition(target_snapshot: Dictionary, duration: float, profile_name: String) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	var from_snapshot: Dictionary = _current_snapshot if not _current_snapshot.is_empty() else target_snapshot

	transition_started.emit(profile_name, duration)

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(
		func(t: float) -> void:
			_current_snapshot = EnvironmentProfile.lerp_snapshot(from_snapshot, target_snapshot, t)
			_controller.apply_snapshot(_current_snapshot),
		0.0, 1.0, duration
	)
	_tween.finished.connect(
		func() -> void:
			_current_snapshot = target_snapshot
			_controller.apply_snapshot(_current_snapshot)
			profile_applied.emit(profile_name)
			transition_finished.emit(profile_name)
	)


func fade_out(duration: float = -1.0) -> void:
	# Atajo semántico: transición hacia el estado neutro (oscurecido/limpio).
	clear_profile(duration)


func fade_in(profile_name: String, duration: float = -1.0) -> void:
	# Atajo semántico: transición desde el estado neutro hacia un perfil.
	apply_profile(profile_name, duration)
