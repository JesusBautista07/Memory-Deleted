class_name EnvironmentProfile
extends Resource

## Contenedor de datos de un perfil de ambientación.
## No contiene lógica de juego. Solo configuración.

@export_group("Niebla")
@export var fog_enabled: bool = false
@export var fog_color: Color = Color(0.6, 0.6, 0.65)
@export var fog_density: float = 0.01
@export var fog_distance: float = 60.0

@export_group("Iluminación Ambiental")
@export var ambient_enabled: bool = true
@export var ambient_color: Color = Color(1.0, 1.0, 1.0)
@export var ambient_intensity: float = 1.0

@export_group("Luces Parpadeantes")
@export var flicker_lights_enabled: bool = false
@export var flicker_min_energy: float = 0.2
@export var flicker_max_energy: float = 1.0
@export var flicker_speed: float = 8.0

@export_group("Lluvia")
@export var rain_enabled: bool = false
@export var rain_intensity: float = 1.0

@export_group("Partículas")
@export var particles_enabled: bool = false
@export var dust_enabled: bool = false
@export var smoke_enabled: bool = false
@export var ash_enabled: bool = false
@export var leaves_enabled: bool = false
@export var particles_intensity: float = 1.0

@export_group("Postprocesado")
@export var postprocess_enabled: bool = false
@export var brightness: float = 1.0
@export var contrast: float = 1.0
@export var saturation: float = 1.0
@export var color_tint: Color = Color(1.0, 1.0, 1.0)
@export var tint_strength: float = 0.0
@export var darkening: float = 0.0

@export_group("Transición")
@export var default_transition_duration: float = 1.5


func get_snapshot() -> Dictionary:
	# Convierte el perfil en un diccionario plano de valores interpolables.
	# Usado por AmbientManager para blends e interpolaciones.
	return {
		"fog_enabled": fog_enabled,
		"fog_color": fog_color,
		"fog_density": fog_density,
		"fog_distance": fog_distance,
		"ambient_enabled": ambient_enabled,
		"ambient_color": ambient_color,
		"ambient_intensity": ambient_intensity,
		"flicker_lights_enabled": flicker_lights_enabled,
		"flicker_min_energy": flicker_min_energy,
		"flicker_max_energy": flicker_max_energy,
		"flicker_speed": flicker_speed,
		"rain_enabled": rain_enabled,
		"rain_intensity": rain_intensity,
		"particles_enabled": particles_enabled,
		"dust_enabled": dust_enabled,
		"smoke_enabled": smoke_enabled,
		"ash_enabled": ash_enabled,
		"leaves_enabled": leaves_enabled,
		"particles_intensity": particles_intensity,
		"postprocess_enabled": postprocess_enabled,
		"brightness": brightness,
		"contrast": contrast,
		"saturation": saturation,
		"color_tint": color_tint,
		"tint_strength": tint_strength,
		"darkening": darkening,
	}


static func lerp_snapshot(from: Dictionary, to: Dictionary, weight: float) -> Dictionary:
	# Interpola linealmente entre dos snapshots. Los booleanos se resuelven
	# por umbral (weight >= 0.5 toma el valor destino).
	var result: Dictionary = {}
	for key in to.keys():
		var from_value = from.get(key, to[key])
		var to_value = to[key]
		if typeof(to_value) == TYPE_BOOL:
			result[key] = to_value if weight >= 0.5 else from_value
		elif typeof(to_value) == TYPE_COLOR:
			result[key] = (from_value as Color).lerp(to_value, weight)
		elif typeof(to_value) == TYPE_FLOAT or typeof(to_value) == TYPE_INT:
			result[key] = lerpf(float(from_value), float(to_value), weight)
		else:
			result[key] = to_value
	return result
