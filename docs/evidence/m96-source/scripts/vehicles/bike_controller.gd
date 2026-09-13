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
var ground_pose := GroundPose.new()
var rider_collision := RiderCollision.new()

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	# A small recovery margin keeps flat chassis edges off terrain triangle seams.
	safe_margin = 0.02
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
	rider_collision.setup(self)
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
			message.emit("%s · Reach 44 km/h, then hold S / back to take off." % transformation.mode)
	transformation.advance(delta)
	var flying := flight.compute_velocity(delta)
	if not flying:
		var throttle := Input.get_axis("move_back", "move_forward") if input_enabled else 0.0
		steering = Input.get_axis("move_left", "move_right") if input_enabled else 0.0
		var load_factor := 1.0 / (1.0 + cargo_mass / 90.0)
		if input_enabled and ((Input.is_action_pressed("jump") and transformation.mode != "AIRCRAFT") or (Input.is_action_pressed("sprint") and transformation.mode == "AIRCRAFT")):
			speed = move_toward(speed, 0, brake_force * delta)
		elif input_enabled and Input.is_action_pressed("jump") and transformation.mode == "AIRCRAFT":
			speed = move_toward(speed,34.0*load_factor,acceleration*load_factor*delta)
		elif throttle != 0:
			var target_speed := maximum_speed * load_factor if throttle > 0 else -5.0
			var rate := acceleration * load_factor if signf(speed) == signf(throttle) or absf(speed) < 0.1 else brake_force
			speed = move_toward(speed, target_speed, rate * delta)
		else:
			speed = move_toward(speed, 0, delta * 5.0)
		var proposed_yaw := rotation.y-steering*delta*1.3*clampf(speed/6.0,-0.7,1.0)
		try_turn(proposed_yaw)
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
	var previous_visual := visual.transform
	ground_pose.sample(self,transformation.mode=="BIKE")
	visual.ground_roll = ground_pose.roll
	visual.animate_vehicle(delta, speed, steering)
	visual.rotation.x = lerpf(visual.rotation.x,flight.pitch if flight.airborne else ground_pose.pitch,1-exp(-delta*12))
	visual.position.y = lerpf(visual.position.y,ground_pose.height,1-exp(-delta*12))
	rider_collision.restrict_pose(previous_visual)
	transformation.sync_wing_pose(previous_visual)
	rider_collision.sync_transform()
	if position.y < -8 or absf(position.x) > WorldStreamer.HALF_EXTENT or absf(position.z) > WorldStreamer.HALF_EXTENT:
		recover()

func try_turn(yaw: float) -> bool:
	# A deployed airborne wing must not gain height from a wing-only floor contact.
	return VehicleClearance.apply_turn(self,yaw,17 if cart_attached else 1,not flight.airborne)

func recover() -> void:
	flight.reset()
	transformation.reset()
	position = home
	velocity = Vector3.ZERO
	speed = 0
	rotation = Vector3.ZERO
	recovered.emit()
