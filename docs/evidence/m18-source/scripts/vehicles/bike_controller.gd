class_name BikeController
extends CharacterBody3D
signal recovered
signal message(text: String)
@export var maximum_speed: float = 22.0
@export var acceleration: float = 8.0
@export var brake_force: float = 18.0
var input_enabled: bool = false
var speed: float = 0.0
var tow_cart: CargoCart
var cart_attached: bool = false
var cargo_mass: float = 0.0
var visual: BikeVisual
var camera_anchor: Node3D
var home := Vector3.ZERO
var steering: float = 0.0
var travelled: float = 0
var transformation := VehicleTransformation.new()
var flight := BikeFlightController.new()

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	floor_snap_length = 0.9
	floor_max_angle = deg_to_rad(50)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.75, 1.1, 2.6)
	collision.shape = shape
	collision.position.y = 0.62
	add_child(collision)
	visual = BikeVisual.new()
	add_child(visual)
	flight.bike = self
	transformation.setup(self)
	camera_anchor = Node3D.new()
	camera_anchor.position.y = 0.7
	add_child(camera_anchor)

func _physics_process(delta: float) -> void:
	if input_enabled and Input.is_action_just_pressed("reset_player"):
		recover()
		return
	var before := position
	if input_enabled and Input.is_action_just_pressed("transform_vehicle"):
		if not transformation.request_toggle():
			message.emit(transformation.last_rejection)
		else:
			message.emit("%s · Reach 44 km/h, then hold Space to take off." % transformation.mode)
	transformation.advance(delta)
	var flying := flight.compute_velocity(delta)
	if not flying:
		var throttle := Input.get_axis("move_back", "move_forward") if input_enabled else 0.0
		steering = Input.get_axis("move_left", "move_right") if input_enabled else 0.0
		var load_factor := 1.0 / (1.0 + cargo_mass / 90.0)
		if input_enabled and Input.is_action_pressed("jump") and transformation.mode != "AIRCRAFT":
			speed = move_toward(speed, 0, brake_force * delta)
		elif throttle != 0:
			var target_speed := maximum_speed * load_factor if throttle > 0 else -5.0
			var rate := acceleration * load_factor if signf(speed) == signf(throttle) or absf(speed) < 0.1 else brake_force
			speed = move_toward(speed, target_speed, rate * delta)
		else:
			speed = move_toward(speed, 0, delta * 5.0)
		rotation.y -= steering * delta * 1.3 * clampf(speed / 6.0, -0.7, 1.0)
		var forward := -global_basis.z
		velocity.x = forward.x * speed
		velocity.z = forward.z * speed
		velocity.y -= delta * 24
	if cart_attached and is_instance_valid(tow_cart):
		var away := position-tow_cart.position
		away.y = 0
		var radial_speed := velocity.dot(away.normalized())
		var allowed := maxf(0,(4.4-away.length())/delta)
		if radial_speed>allowed:
			velocity -= away.normalized()*(radial_speed-allowed)
			speed = signf(speed)*minf(absf(speed),Vector2(velocity.x,velocity.z).length())
	move_and_slide()
	flight.after_move()
	if is_on_wall():
		speed = signf(speed) * minf(absf(speed), Vector2(velocity.x, velocity.z).length())
	travelled += position.distance_to(before)
	visual.animate_vehicle(delta, speed, steering)
	visual.rotation.x = lerpf(visual.rotation.x,flight.pitch if flight.airborne else 0.0,delta*6)
	if position.y < -8 or absf(position.x) > WorldStreamer.HALF_EXTENT or absf(position.z) > WorldStreamer.HALF_EXTENT:
		recover()

func recover() -> void:
	flight.reset()
	transformation.reset()
	position = home
	velocity = Vector3.ZERO
	speed = 0
	rotation = Vector3.ZERO
	recovered.emit()
