class_name VehicleSeat
extends Node
signal changed
signal message(text: String)
var actor: PlayerController
var bike: BikeController
var orbit: OrbitCamera
var combat: PlayerCombat
var enabled: bool = false
var mounted: bool = false
var transition_count: int = 0

func _ready() -> void:
	process_physics_priority = -20
	combat.health.died.connect(func():
		if mounted:
			leave(true)
	)
	bike.recovered.connect(func():
		if mounted:
			actor.position = bike.position
			orbit.snap()
	)

func can_mount() -> bool:
	if not bike.is_on_floor() or absf(bike.speed)>2 or bike.flight.airborne or bike.transformation.mode not in ["BIKE","AIRCRAFT"]:
		return false
	return enabled and not mounted and combat.health.current > 0 and actor.is_on_floor() and actor.dodge_remaining <= 0 and not Input.is_action_pressed("jump") and not Input.is_action_pressed("dodge") and actor.position.distance_to(bike.position) < 3.0 and DamageSystem.clear_line(actor.get_world_3d(), actor.position + Vector3.UP, bike.position + Vector3.UP) and bike.rider_collision.can_fit(bike.visual.transform,actor)

func enter() -> bool:
	if not can_mount():
		if enabled and not mounted and actor.position.distance_to(bike.position)<3 and not bike.rider_collision.can_fit(bike.visual.transform,actor):
			message.emit("Not enough room above the seat. The rider needs clear space.")
		return false
	mounted = true
	bike.rider_collision.set_mounted(true)
	transition_count += 1
	combat.cancel()
	combat.target = null
	actor.velocity = Vector3.ZERO
	actor.collision_layer = 0
	actor.collision_mask = 0
	actor.visible = false
	bike.visual.rider.visible = true
	orbit.follow_target = bike.camera_anchor
	orbit.heading_target = bike
	orbit.manual_look_remaining = 0
	orbit.distance = 7.5
	changed.emit()
	orbit.snap()
	message.emit("Motorcycle · WASD drive · Space brake · E dismount")
	return true

func _exit_point() -> Variant:
	var space := actor.get_world_3d().direct_space_state
	var offsets := [Vector3(1.7,0,0),Vector3(-1.7,0,0),Vector3(0,0,2.2),Vector3(0,0,-2.2)]
	if bike.transformation.mode=="AIRCRAFT":
		# Leave clear of both the deployed wings and the tail/propeller.
		offsets = [Vector3(0,0,-2.2),Vector3(5,0,0),Vector3(-5,0,0)]
	for offset: Vector3 in offsets:
		var candidate: Vector3 = bike.position + offset.rotated(Vector3.UP, bike.rotation.y)
		var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 2, candidate - Vector3.UP * 3, 1))
		if floor_hit.is_empty() or floor_hit.normal.y < 0.65:
			continue
		candidate = floor_hit.position + Vector3.UP * 0.08
		if absf(candidate.y - bike.position.y) > 1.0 or not DamageSystem.clear_line(actor.get_world_3d(), bike.position + Vector3.UP, candidate + Vector3.UP):
			continue
		var query := PhysicsShapeQueryParameters3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.35
		shape.height = 1.85
		query.shape = shape
		query.transform.origin = candidate + Vector3.UP * 0.95
		query.collision_mask = 13
		query.exclude = [actor.get_rid()]
		if space.intersect_shape(query).is_empty():
			return candidate
	return null

func leave(force: bool = false) -> bool:
	if not mounted or (not enabled and not force):
		return false
	if not force and (not bike.is_on_floor() or bike.transformation.mode in ["DEPLOYING","FOLDING"]):
		message.emit("Wait for grounded contact and finished wing movement before dismounting.")
		return false
	if force and bike.transformation.mode in ["DEPLOYING","FOLDING"]:
		bike.transformation.reset()
	if bike.flight.airborne:
		if not force:
			message.emit("Land before leaving the aircraft.")
			return false
		bike.recover()
	if absf(bike.speed) > 2.0 and not force:
		message.emit("Brake to a stop before dismounting.")
		return false
	var point: Variant = _exit_point()
	if point == null and not force:
		message.emit("No clear ground. Move the bike to dismount.")
		return false
	mounted = false
	bike.rider_collision.set_mounted(false)
	transition_count += 1
	actor.position = actor.spawn_position if point == null else point
	actor.velocity = Vector3.ZERO
	actor.collision_layer = 2
	actor.collision_mask = 13
	actor.visible = true
	bike.visual.rider.visible = false
	bike.speed = 0
	bike.velocity = Vector3.ZERO
	orbit.follow_target = actor
	orbit.heading_target = null
	orbit.manual_look_remaining = 0
	orbit.distance = 6.2
	changed.emit()
	orbit.snap()
	return true

func _physics_process(_delta: float) -> void:
	if mounted:
		actor.position = bike.position
	if enabled and Input.is_action_just_pressed("interact"):
		if mounted:
			leave()
		elif actor.position.distance_to(bike.position)<3:
			enter()

func restore_ownership(value: bool) -> void:
	mounted = value
	bike.rider_collision.set_mounted(value)
	actor.visible = not value
	actor.collision_layer = 0 if value else 2
	actor.collision_mask = 0 if value else 13
	bike.visual.rider.visible = value
	orbit.follow_target = bike.camera_anchor if value else actor
	orbit.heading_target = bike if value else null
	orbit.manual_look_remaining = 0
	orbit.distance = 7.5 if value else 6.2
	if value: actor.position = bike.position
	changed.emit()
