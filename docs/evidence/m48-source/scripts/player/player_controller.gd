class_name PlayerController
extends CharacterBody3D

signal recovered
signal jumped
signal dodged

@export var config: MovementConfig
var orbit: OrbitCamera
var visual: PlayerVisual
var stamina: float = 100.0
var speed_multiplier: float = 1.0
var surface_speed_multiplier: float = 1.0
var input_enabled: bool = false
var spawn_position := Vector3(0, 2, 12)
var dodge_remaining: float = 0.0
var dodge_direction := Vector3.FORWARD
var regen_delay: float = 0.0
var coyote: float = 0.0
var jump_buffer: float = 0.0
var sprint_exhausted: bool = false
var state: String = "IDLE"
var movement_distance: float = 0.0
var jumps: int = 0
var rolls: int = 0

func _ready() -> void:
	if config == null:
		config = MovementConfig.new()
	collision_layer = 2
	collision_mask = 13
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(48)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.85
	collider.shape = capsule
	collider.position.y = 0.94
	add_child(collider)
	visual = PlayerVisual.new()
	add_child(visual)

func spend_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	stamina -= amount
	regen_delay = 0.65
	return true

func recover() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	dodge_remaining = 0.0
	jump_buffer = 0.0
	stamina = config.stamina_max
	sprint_exhausted = false
	if orbit:
		orbit.snap()
	recovered.emit()

func _physics_process(delta: float) -> void:
	var before := global_position
	coyote = 0.12 if is_on_floor() else maxf(0.0, coyote - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	regen_delay = maxf(0.0, regen_delay - delta)
	var axis := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if input_enabled else Vector2.ZERO
	var direction := Vector3(axis.x, 0, axis.y).rotated(Vector3.UP, orbit.yaw if orbit else 0.0)
	var sprinting := input_enabled and Input.is_action_pressed("sprint") and axis.length() > 0.1 and not sprint_exhausted and is_on_floor() and dodge_remaining <= 0.0
	if not Input.is_action_pressed("sprint") and stamina > 20.0:
		sprint_exhausted = false
	if input_enabled and Input.is_action_just_pressed("reset_player"):
		recover()
		return
	if input_enabled and Input.is_action_just_pressed("jump"):
		jump_buffer = 0.14
	if input_enabled and Input.is_action_just_pressed("dodge") and is_on_floor() and dodge_remaining <= 0.0 and spend_stamina(config.dodge_cost):
		dodge_remaining = config.dodge_duration
		dodge_direction = direction.normalized() if direction.length() > 0.1 else Vector3.FORWARD.rotated(Vector3.UP, visual.rotation.y)
		rolls += 1
		dodged.emit()
	if jump_buffer > 0.0 and coyote > 0.0 and dodge_remaining <= 0.0 and spend_stamina(config.jump_cost):
		velocity.y = config.jump_velocity
		coyote = 0.0
		jump_buffer = 0.0
		jumps += 1
		jumped.emit()
	velocity.y -= config.gravity * delta
	if dodge_remaining > 0.0:
		dodge_remaining = maxf(0.0, dodge_remaining - delta)
		velocity.x = dodge_direction.x * config.dodge_speed
		velocity.z = dodge_direction.z * config.dodge_speed
		state = "DODGE"
	else:
		if sprinting:
			stamina = maxf(0.0, stamina - config.sprint_drain * delta)
			regen_delay = 0.6
			if stamina <= 0.0:
				sprint_exhausted = true
		elif regen_delay <= 0.0:
			stamina = minf(config.stamina_max, stamina + config.stamina_regen * delta)
		var speed := (config.sprint_speed if sprinting else config.walk_speed) * speed_multiplier * surface_speed_multiplier
		var acceleration := config.ground_acceleration if is_on_floor() else config.air_acceleration
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
		state = "SPRINT" if sprinting else ("WALK" if axis.length() > 0.1 else "IDLE")
		if not is_on_floor():
			state = "AIRBORNE"
	if direction.length() > 0.1 and dodge_remaining <= 0.0:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-16.0 * delta))
	move_and_slide()
	movement_distance += Vector2(global_position.x - before.x, global_position.z - before.z).length()
	visual.animate(delta, Vector2(velocity.x, velocity.z).length(), is_on_floor(), 1.0 - dodge_remaining / config.dodge_duration if dodge_remaining > 0.0 else -1.0)
	if global_position.y < -8.0 or absf(global_position.x) > WorldStreamer.HALF_EXTENT or absf(global_position.z) > WorldStreamer.HALF_EXTENT:
		recover()

func set_controls(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		jump_buffer = 0.0
		dodge_remaining = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
