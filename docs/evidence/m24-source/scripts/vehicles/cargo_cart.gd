class_name CargoCart
extends CharacterBody3D
var inventory := Inventory.new()
var tow_vehicle: BikeController
var cargo_visual: Node3D
var wheels: Array[Node3D] = []
var travelled: float = 0
var enabled: bool = true

func _ready() -> void:
	collision_layer = 17
	collision_mask = 1
	floor_snap_length = 1.1
	floor_max_angle = deg_to_rad(50)
	inventory.capacity = 160
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.65,1.0,2.0)
	collider.shape = shape
	collider.position.y = 0.8
	add_child(collider)
	BlockoutKit.box(self,Vector3(0,0.65,0),Vector3(1.65,0.2,2),Color("866044"))
	for side in [-1,1]:
		BlockoutKit.box(self,Vector3(side*0.8,1.06,0),Vector3(0.12,0.65,2),Color("996943"))
		var wheel := BlockoutKit.cylinder(self,Vector3(side*0.94,0.44,0.25),0.44,0.20,Color("293632"))
		wheel.rotation.z = PI/2
		wheels.append(wheel)
	BlockoutKit.box(self,Vector3(0,1.06,0.94),Vector3(1.6,0.65,0.12),Color("996943"))
	BlockoutKit.box(self,Vector3(0,0.53,-1.65),Vector3(0.13,0.13,1.4),Color("8e754d"))
	cargo_visual = Node3D.new()
	add_child(cargo_visual)
	inventory.changed.connect(_update_cargo)

func _update_cargo() -> void:
	for child in cargo_visual.get_children():
		cargo_visual.remove_child(child)
		child.queue_free()
	var amount := mini(8,ceili(inventory.mass()/10.0))
	for i in range(amount):
		BlockoutKit.box(cargo_visual,Vector3((i%2-0.5)*0.65,0.98+(i/4)*0.48,((i/2)%2-0.5)*0.7),Vector3(0.6,0.45,0.65),Color("c0925e"))
	if tow_vehicle: tow_vehicle.cargo_mass = inventory.mass()+20

func _physics_process(delta: float) -> void:
	if not enabled: return
	var from := position
	if tow_vehicle:
		var hitch := tow_vehicle.position + tow_vehicle.global_basis.z*1.3
		var offset := position-hitch
		offset.y = 0
		if offset.length()>0.1:
			rotation.y = lerp_angle(rotation.y,atan2(offset.x,offset.z),minf(1,delta*8))
		var desired := hitch + global_basis.z*2.0
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
	var distance := from.distance_to(position)
	travelled += distance
	for wheel in wheels: wheel.rotate_y(distance/0.44)
