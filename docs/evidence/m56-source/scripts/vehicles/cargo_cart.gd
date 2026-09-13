class_name CargoCart
extends CharacterBody3D
var inventory := Inventory.new()
var tow_vehicle: BikeController
var cargo_visual: Node3D
var wheels: Array[Node3D] = []
var travelled: float = 0
var enabled: bool = true
var visual: CartVisual
var ground_pose := GroundPose.new()

func _ready() -> void:
	collision_layer = 17
	collision_mask = 9
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
	wheels = visual.wheels
	cargo_visual = visual.cargo
	inventory.changed.connect(_update_cargo)

func _update_cargo() -> void:
	visual.set_load(inventory.mass())
	if tow_vehicle: tow_vehicle.cargo_mass = inventory.mass()+20

func _physics_process(delta: float) -> void:
	if not enabled: return
	var from := position
	if tow_vehicle:
		var hitch := tow_vehicle.position + tow_vehicle.global_basis.z*1.3
		var offset := position-hitch
		offset.y = 0
		if offset.length()>0.1:
			var proposed_yaw := lerp_angle(rotation.y,atan2(offset.x,offset.z),minf(1,delta*8))
			if VehicleClearance.turn_clear(self,proposed_yaw,8): rotation.y = proposed_yaw
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
	var blend := 1-exp(-delta*12)
	visual.rotation.x = lerpf(visual.rotation.x,ground_pose.pitch,blend)
	visual.rotation.z = lerpf(visual.rotation.z,ground_pose.roll,blend)
	visual.position.y = lerpf(visual.position.y,ground_pose.height,blend)
	var distance := from.distance_to(position)
	travelled += distance
	visual.animate_travel(distance)
