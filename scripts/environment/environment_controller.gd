class_name EnvironmentController
extends Node

## Aplica valores de ambientación a nodos ya existentes en la escena.
## Nunca crea niebla, luces, partículas ni sonidos.
## Nunca construye escenarios. Solo controla lo que ya existe.
##
## Localiza sus objetivos mediante grupos, para permanecer agnóstico
## a la estructura concreta de cada escenario:
##   env_world_environment  -> WorldEnvironment
##   env_flicker_lights     -> Light3D (uno o varios)
##   env_rain               -> GPUParticles3D / GPUParticles2D
##   env_dust                -> GPUParticles3D / GPUParticles2D
##   env_smoke               -> GPUParticles3D / GPUParticles2D
##   env_ash                 -> GPUParticles3D / GPUParticles2D
##   env_leaves               -> GPUParticles3D / GPUParticles2D
##   env_darken_overlay      -> CanvasItem con propiedad modulate (alpha)

const GROUP_WORLD_ENVIRONMENT: String = "env_world_environment"
const GROUP_FLICKER_LIGHTS: String = "env_flicker_lights"
const GROUP_RAIN: String = "env_rain"
const GROUP_DUST: String = "env_dust"
const GROUP_SMOKE: String = "env_smoke"
const GROUP_ASH: String = "env_ash"
const GROUP_LEAVES: String = "env_leaves"
const GROUP_DARKEN_OVERLAY: String = "env_darken_overlay"

var _world_environment: WorldEnvironment
var _flicker_lights: Array[Light3D] = []
var _particle_groups: Dictionary = {}
var _darken_overlays: Array[CanvasItem] = []

var _flicker_enabled: bool = false
var _flicker_min: float = 0.2
var _flicker_max: float = 1.0
var _flicker_speed: float = 8.0
var _flicker_time: float = 0.0

var _fog_master_enabled: bool = true
var _rain_master_enabled: bool = true
var _particles_master_enabled: bool = true
var _postprocess_master_enabled: bool = true


func _ready() -> void:
	set_process(true)
	refresh_references()


func refresh_references() -> void:
	# Vuelve a buscar los nodos objetivo en el árbol. Tolera su ausencia.
	var wenv_nodes := get_tree().get_nodes_in_group(GROUP_WORLD_ENVIRONMENT)
	_world_environment = wenv_nodes[0] if wenv_nodes.size() > 0 else null

	_flicker_lights.clear()
	for node in get_tree().get_nodes_in_group(GROUP_FLICKER_LIGHTS):
		if node is Light3D:
			_flicker_lights.append(node)

	_particle_groups = {
		"rain": get_tree().get_nodes_in_group(GROUP_RAIN),
		"dust": get_tree().get_nodes_in_group(GROUP_DUST),
		"smoke": get_tree().get_nodes_in_group(GROUP_SMOKE),
		"ash": get_tree().get_nodes_in_group(GROUP_ASH),
		"leaves": get_tree().get_nodes_in_group(GROUP_LEAVES),
	}

	_darken_overlays.clear()
	for node in get_tree().get_nodes_in_group(GROUP_DARKEN_OVERLAY):
		if node is CanvasItem:
			_darken_overlays.append(node)


func _process(delta: float) -> void:
	if not _flicker_enabled or _flicker_lights.is_empty():
		return
	_flicker_time += delta * _flicker_speed
	var t: float = (sin(_flicker_time) + 1.0) * 0.5
	var energy: float = lerpf(_flicker_min, _flicker_max, t)
	for light in _flicker_lights:
		if is_instance_valid(light):
			light.light_energy = energy


func apply_snapshot(snapshot: Dictionary) -> void:
	_apply_fog(snapshot)
	_apply_ambient(snapshot)
	_apply_flicker(snapshot)
	_apply_rain(snapshot)
	_apply_particles(snapshot)
	_apply_postprocess(snapshot)


# ---------------------------------------------------------------------------
# Niebla / Iluminación ambiental
# ---------------------------------------------------------------------------

func _apply_fog(snapshot: Dictionary) -> void:
	if _world_environment == null or _world_environment.environment == null:
		return
	var env: Environment = _world_environment.environment
	var enabled: bool = snapshot.get("fog_enabled", false) and _fog_master_enabled
	env.fog_enabled = enabled
	if enabled:
		env.fog_light_color = snapshot.get("fog_color", env.fog_light_color)
		env.fog_density = snapshot.get("fog_density", env.fog_density)
		env.fog_depth_end = snapshot.get("fog_distance", env.fog_depth_end)


func _apply_ambient(snapshot: Dictionary) -> void:
	if _world_environment == null or _world_environment.environment == null:
		return
	var env: Environment = _world_environment.environment
	var enabled: bool = snapshot.get("ambient_enabled", true)
	if enabled:
		env.ambient_light_color = snapshot.get("ambient_color", env.ambient_light_color)
		env.ambient_light_energy = snapshot.get("ambient_intensity", env.ambient_light_energy)
	else:
		env.ambient_light_energy = 0.0


# ---------------------------------------------------------------------------
# Luces parpadeantes
# ---------------------------------------------------------------------------

func _apply_flicker(snapshot: Dictionary) -> void:
	_flicker_enabled = snapshot.get("flicker_lights_enabled", false)
	_flicker_min = snapshot.get("flicker_min_energy", _flicker_min)
	_flicker_max = snapshot.get("flicker_max_energy", _flicker_max)
	_flicker_speed = snapshot.get("flicker_speed", _flicker_speed)
	if not _flicker_enabled:
		for light in _flicker_lights:
			if is_instance_valid(light):
				light.light_energy = _flicker_max


# ---------------------------------------------------------------------------
# Lluvia / Partículas
# ---------------------------------------------------------------------------

func _apply_rain(snapshot: Dictionary) -> void:
	var enabled: bool = snapshot.get("rain_enabled", false) and _rain_master_enabled
	var intensity: float = snapshot.get("rain_intensity", 1.0)
	_set_particle_group_state("rain", enabled, intensity)


func _apply_particles(snapshot: Dictionary) -> void:
	var master_enabled: bool = snapshot.get("particles_enabled", false) and _particles_master_enabled
	var intensity: float = snapshot.get("particles_intensity", 1.0)
	_set_particle_group_state("dust", master_enabled and snapshot.get("dust_enabled", false), intensity)
	_set_particle_group_state("smoke", master_enabled and snapshot.get("smoke_enabled", false), intensity)
	_set_particle_group_state("ash", master_enabled and snapshot.get("ash_enabled", false), intensity)
	_set_particle_group_state("leaves", master_enabled and snapshot.get("leaves_enabled", false), intensity)


func _set_particle_group_state(group_key: String, enabled: bool, intensity: float) -> void:
	var nodes: Array = _particle_groups.get(group_key, [])
	for node in nodes:
		if not is_instance_valid(node):
			continue
		if "emitting" in node:
			node.emitting = enabled
		if enabled and "amount_ratio" in node:
			node.amount_ratio = clampf(intensity, 0.0, 1.0)


# ---------------------------------------------------------------------------
# Postprocesado
# ---------------------------------------------------------------------------

func _apply_postprocess(snapshot: Dictionary) -> void:
	var enabled: bool = snapshot.get("postprocess_enabled", false) and _postprocess_master_enabled

	if _world_environment != null and _world_environment.environment != null:
		var env: Environment = _world_environment.environment
		env.adjustment_enabled = enabled
		if enabled:
			env.adjustment_brightness = snapshot.get("brightness", 1.0)
			env.adjustment_contrast = snapshot.get("contrast", 1.0)
			env.adjustment_saturation = snapshot.get("saturation", 1.0)

	var darkening: float = snapshot.get("darkening", 0.0) if enabled else 0.0
	var tint: Color = snapshot.get("color_tint", Color.WHITE)
	var tint_strength: float = snapshot.get("tint_strength", 0.0) if enabled else 0.0
	for overlay in _darken_overlays:
		if not is_instance_valid(overlay):
			continue
		var overlay_color: Color = tint
		overlay_color.a = clampf(darkening + tint_strength, 0.0, 1.0)
		overlay.modulate = overlay_color


# ---------------------------------------------------------------------------
# Interruptores maestros por categoría (API pública de bajo nivel)
# ---------------------------------------------------------------------------

func set_fog_master_enabled(enabled: bool) -> void:
	_fog_master_enabled = enabled


func set_rain_master_enabled(enabled: bool) -> void:
	_rain_master_enabled = enabled


func set_particles_master_enabled(enabled: bool) -> void:
	_particles_master_enabled = enabled


func set_postprocess_master_enabled(enabled: bool) -> void:
	_postprocess_master_enabled = enabled
