class_name VehicleTransformation
extends RefCounted
signal mode_changed(mode: String)
var bike: BikeController
var mode: String = "BIKE"
var progress: float = 0.0
var pivots: Array[Node3D] = []
var tail: Node3D
var propeller: Node3D
var wing_collision: CollisionShape3D
var last_rejection: String = ""

func setup(owner_bike: BikeController) -> void:
	bike = owner_bike
	for side in [-1.0,1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side*0.35,1.55,0.05)
		bike.visual.add_child(pivot)
		BlockoutKit.box(pivot,Vector3(side*2.0,0,0),Vector3(4.0,0.10,1.2),Color("e6d6af"))
		BlockoutKit.box(pivot,Vector3(side*3.55,0.015,0),Vector3(0.88,0.12,1.22),Color("a44837"))
		pivots.append(pivot)
	tail = Node3D.new()
	bike.visual.add_child(tail)
	BlockoutKit.box(tail,Vector3(0,1.08,1.7),Vector3(0.12,0.12,1.8),Color("8e754d"))
	BlockoutKit.box(tail,Vector3(0,1.75,2.4),Vector3(0.12,1.4,0.75),Color("e6d6af"))
	BlockoutKit.box(tail,Vector3(0,2.4,2.4),Vector3(0.14,0.20,0.76),Color("a44837"))
	BlockoutKit.box(tail,Vector3(0,1.2,2.4),Vector3(2.2,0.09,0.65),Color("e6d6af"))
	propeller = Node3D.new()
	propeller.position = Vector3(0,1.16,2.9)
	tail.add_child(propeller)
	BlockoutKit.box(propeller,Vector3.ZERO,Vector3(1.8,0.10,0.10),Color("46534e"))
	wing_collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8.8,0.18,1.2)
	wing_collision.shape = shape
	wing_collision.position.y = 1.55
	wing_collision.disabled = true
	bike.add_child(wing_collision)
	_present()

func request_toggle() -> bool:
	last_rejection = ""
	if bike.cart_attached:
		last_rejection = "Detach the ground cart before deploying wings."
		return false
	if mode in ["DEPLOYING","FOLDING"]:
		last_rejection = "Transformation already in progress."
		return false
	if mode == "AIRCRAFT":
		if bike.flight.airborne or not bike.is_on_floor() or absf(bike.speed)>8:
			last_rejection = "Land and slow down before folding the wings."
			return false
		mode = "FOLDING"
	else:
		if not bike.is_on_floor() or absf(bike.speed)>8:
			last_rejection = "Deploy from stable ground."
			return false
		if not clearance():
			last_rejection = "Move into open ground before deploying wings."
			return false
		mode = "DEPLOYING"
	mode_changed.emit(mode)
	return true

func advance(delta: float) -> void:
	if mode == "DEPLOYING":
		progress = move_toward(progress,1.0,delta/1.1)
		if progress>=1 and not clearance():
			mode = "FOLDING"
			last_rejection = "Wing space became blocked; folding safely."
		elif progress>=1:
			mode = "AIRCRAFT"
			mode_changed.emit(mode)
	elif mode == "FOLDING":
		progress = move_toward(progress,0.0,delta/1.1)
		if progress<=0:
			mode = "BIKE"
			mode_changed.emit(mode)
	_present()
	propeller.rotation.z += delta * absf(bike.speed)*1.5

func _present() -> void:
	for i in range(pivots.size()):
		var side := -1.0 if i==0 else 1.0
		pivots[i].visible = progress>0.01
		pivots[i].rotation.z = side*(1.0-progress)*PI*0.46
		pivots[i].scale.x = maxf(0.05,progress)
	tail.visible = progress>0.05
	tail.scale = Vector3.ONE * maxf(0.05,progress)
	wing_collision.disabled = mode != "AIRCRAFT"

func reset() -> void:
	progress = 0
	mode = "BIKE"
	_present()

func clearance() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = wing_collision.shape
	query.transform = bike.global_transform * Transform3D(Basis.IDENTITY,Vector3(0,1.55,0))
	query.collision_mask = 1
	return bike.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
