extends CharacterBody3D
class_name PlayerMovement
## Sistema de movimiento del jugador en primera persona.
## Responsable ÚNICAMENTE de: input WASD, caminar/correr, agacharse,
## salto, gravedad, colisiones, movimiento en pendientes y reinicio por caída.
## No gestiona cámara, mouse-look, inventario ni interacción.

# ---------------------------------------------------------------------------
# CONFIGURACIÓN EXPORTADA (ajustable desde el Inspector, sin tocar código)
# ---------------------------------------------------------------------------

@export_group("Velocidades")
@export var walk_speed: float = 4.0
@export var run_speed: float = 7.0
@export var crouch_speed: float = 2.0
@export var acceleration: float = 10.0   # suavizado de aceleración/frenado

@export_group("Salto y Gravedad")
@export var jump_velocity: float = 4.5
@export var gravity_multiplier: float = 1.0   # por si se necesita ajustar el "peso" del jugador

@export_group("Agacharse (Ctrl)")
@export var can_crouch: bool = true
@export var crouch_height_scale: float = 0.5   # % de la altura original de la cápsula

@export_group("Pendientes")
@export var floor_max_angle_deg: float = 46.0   # ángulo máximo caminable

@export_group("Reinicio automático por caída")
@export var enable_fall_reset: bool = true
@export var fall_reset_y: float = -30.0

# ---------------------------------------------------------------------------
# ESTADO INTERNO
# ---------------------------------------------------------------------------

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_crouching: bool = false
var respawn_position: Vector3 = Vector3.ZERO

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _original_capsule_height: float = 0.0
var _original_capsule_pos_y: float = 0.0


# ---------------------------------------------------------------------------
# CICLO DE VIDA
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Guarda la posición inicial como punto de reinicio si el jugador cae del mapa.
	respawn_position = global_position

	# Traduce el ángulo máximo de pendiente (definido en grados por comodidad) a radianes,
	# que es lo que espera CharacterBody3D.
	floor_max_angle = deg_to_rad(floor_max_angle_deg)

	# Guarda las medidas originales de la cápsula de colisión para poder
	# restaurarlas correctamente al dejar de agacharse.
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var capsule := collision_shape.shape as CapsuleShape3D
		_original_capsule_height = capsule.height
		_original_capsule_pos_y = collision_shape.position.y
	elif can_crouch:
		push_warning("PlayerMovement: se esperaba un CapsuleShape3D en CollisionShape3D para agacharse correctamente.")


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_crouch_input()
	_handle_jump_input()
	_handle_horizontal_movement(delta)

	# move_and_slide() ya gestiona colisiones y, junto con floor_max_angle,
	# el deslizamiento correcto sobre pendientes caminables.
	move_and_slide()

	_check_fall_reset()


# ---------------------------------------------------------------------------
# GRAVEDAD
# ---------------------------------------------------------------------------

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * gravity_multiplier * delta


# ---------------------------------------------------------------------------
# SALTO
# ---------------------------------------------------------------------------

func _handle_jump_input() -> void:
	# No se permite saltar estando agachado (comportamiento típico de terror/exploración).
	if is_on_floor() and not is_crouching and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity


# ---------------------------------------------------------------------------
# AGACHARSE (Ctrl) — funcional y preparado para ampliarse (ej. sigilo)
# ---------------------------------------------------------------------------

func _handle_crouch_input() -> void:
	if not can_crouch:
		return

	var wants_crouch := Input.is_action_pressed("crouch")

	if wants_crouch and not is_crouching:
		is_crouching = true
		_resize_collision_shape(true)
	elif not wants_crouch and is_crouching:
		is_crouching = false
		_resize_collision_shape(false)


func _resize_collision_shape(crouching: bool) -> void:
	if collision_shape == null or not (collision_shape.shape is CapsuleShape3D):
		return

	var capsule := collision_shape.shape as CapsuleShape3D

	if crouching:
		capsule.height = _original_capsule_height * crouch_height_scale
	else:
		capsule.height = _original_capsule_height

	# Reposiciona la cápsula para que "crezca hacia abajo" (los pies no flotan).
	collision_shape.position.y = _original_capsule_pos_y - (_original_capsule_height - capsule.height) / 2.0


# ---------------------------------------------------------------------------
# MOVIMIENTO HORIZONTAL (WASD, caminar/correr, pendientes)
# ---------------------------------------------------------------------------

func _handle_horizontal_movement(delta: float) -> void:
	var target_speed := walk_speed
	if is_crouching:
		target_speed = crouch_speed
	elif Input.is_action_pressed("sprint"):
		target_speed = run_speed

	# Vector de input normalizado en el plano XZ.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# La dirección se calcula respecto a la orientación (yaw) del propio CharacterBody3D.
	# Esto asume que el giro horizontal del jugador (mouse-look) se aplica a este mismo
	# nodo desde el sistema de cámara, que queda fuera de este script.
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var target_velocity_x := direction.x * target_speed
	var target_velocity_z := direction.z * target_speed

	# Suaviza la aceleración/frenado en vez de aplicar velocidad instantánea:
	# se siente más natural y evita "teletransportes" de velocidad.
	velocity.x = move_toward(velocity.x, target_velocity_x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity_z, acceleration * delta)


# ---------------------------------------------------------------------------
# REINICIO AUTOMÁTICO SI EL JUGADOR CAE FUERA DEL MAPA
# ---------------------------------------------------------------------------

func _check_fall_reset() -> void:
	if enable_fall_reset and global_position.y < fall_reset_y:
		velocity = Vector3.ZERO
		global_position = respawn_position
