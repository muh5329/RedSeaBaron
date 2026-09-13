class_name CargoCart
extends CharacterBody3D
signal recovered
signal message(text: String)
const MINIMUM_WORLD_Y: float = -64.0
var home := Vector3.ZERO
var inventory := Inventory.new()
var tow_vehicle: BikeController
var cargo_visual: Node3D
var wheels: Array[Node3D] = []
var travelled: float = 0
var enabled: bool = true
var visual: CartVisual
var ground_pose := GroundPose.new()
var canopy_collision: CollisionShape3D

func _ready() -> void:
	add_to_group("navigation_obstacles")
	home = position
	collision_layer = 17
	collision_mask = VehicleClearance.WORLD_AND_NPCS | 8
	floor_snap_length = 1.1
	floor_max_angle = deg_to_rad(50)
	inventory.capacity = 160
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.65,1.3,2.0)
	collider.shape = shape
	collider.position.y = 0.65
	add_child(collider)
	visual = CartVisual.new()
	add_child(visual)
	canopy_collision = CollisionShape3D.new()
	var cover_shape := ConvexPolygonShape3D.new()
	cover_shape.points = CartCanopy.collision_points()
	canopy_collision.shape = cover_shape
	add_child(canopy_collision)
	wheels = visual.wheels
	cargo_visual = visual.cargo
	inventory.changed.connect(_update_cargo)

func _update_cargo() -> void:
	visual.set_load(inventory.mass())
	if tow_vehicle: tow_vehicle.cargo_mass = inventory.mass()+20

func _physics_process(delta: float) -> void:
	if not enabled: return
	if position.y<MINIMUM_WORLD_Y or absf(position.x)>WorldStreamer.HALF_EXTENT or absf(position.z)>WorldStreamer.HALF_EXTENT:
		recover()
		message.emit("Cargo returned to the workshop. All goods preserved.")
		return
	var from := position
	if tow_vehicle:
		var hitch := tow_vehicle.position + tow_vehicle.global_basis.z*1.3
		var offset := position-hitch
		offset.y = 0
		if offset.length()>0.1:
			var proposed_yaw := lerp_angle(rotation.y,atan2(offset.x,offset.z),minf(1,delta*8))
			VehicleClearance.apply_turn(self,proposed_yaw,collision_mask)
		# Solve the drawbar from the real axle-to-hitch direction. Using the
		# smoothed visual yaw here can drag a jackknifed cart beside the bike.
		var drawbar_direction := offset.normalized() if offset.length()>0.1 else tow_vehicle.global_basis.z
		var desired := hitch + drawbar_direction*2.0
		var pull := (desired-position)/delta
		velocity.x = clampf(pull.x,-35,35)
		velocity.z = clampf(pull.z,-35,35)
		if offset.length()>5.0:
			tow_vehicle.speed = move_toward(tow_vehicle.speed,0,delta*60)
	else:
		velocity.x = move_toward(velocity.x,0,delta*25)
		velocity.z = move_toward(velocity.z,0,delta*25)
	velocity.y -= delta*24
	move_and_slide()
	ground_pose.sample(self)
	var previous_visual := visual.transform
	var blend := 1-exp(-delta*12)
	visual.rotation.x = lerpf(visual.rotation.x,ground_pose.pitch,blend)
	visual.rotation.z = lerpf(visual.rotation.z,ground_pose.roll,blend)
	visual.position.y = lerpf(visual.position.y,ground_pose.height,blend)
	_sync_canopy(previous_visual)
	var distance := from.distance_to(position)
	travelled += distance
	var displacement := position-from
	if is_on_floor() and Vector2(displacement.x,displacement.z).length_squared()>0.00000001:
		var rolling_direction := (-global_basis.z).slide(get_floor_normal()).normalized()
		visual.animate_travel(displacement.dot(rolling_direction))

func _sync_canopy(previous_visual: Transform3D) -> void:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = canopy_collision.shape
	query.transform = global_transform*visual.transform
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	if not get_world_3d().direct_space_state.intersect_shape(query).is_empty():
		visual.transform = previous_visual
	canopy_collision.transform = visual.transform

func recover() -> void:
	# A coupled recovery belongs to the bike so seat and drawbar listeners agree.
	if is_instance_valid(tow_vehicle):
		tow_vehicle.recover()
	else:
		position = home
		rotation = Vector3.ZERO
		velocity = Vector3.ZERO
	recovered.emit()
