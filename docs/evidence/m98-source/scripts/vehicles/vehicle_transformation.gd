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
var transition_shapes: Array[CollisionShape3D] = []
var transition_blocked: bool = false
var rear_collision := AircraftTailCollision.new()

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
	propeller.position = Vector3(0,1.45,-1.9)
	tail.add_child(propeller)
	VehicleMesh.rod(tail,Vector3(0,1.3,-1.0),Vector3(0,1.45,-1.9),0.085,Color("8e754d"))
	var hub := BlockoutKit.cylinder(propeller,Vector3.ZERO,0.14,0.24,Color("b39358"),-1,12)
	hub.rotation.x = PI/2
	BlockoutKit.box(propeller,Vector3.ZERO,Vector3(1.8,0.10,0.10),Color("46534e"))
	wing_collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8.8,0.18,1.2)
	wing_collision.shape = shape
	wing_collision.name = "WingFullCollision"
	wing_collision.position.y = 1.55
	wing_collision.disabled = true
	bike.add_child(wing_collision)
	for i in range(2):
		var collision := CollisionShape3D.new()
		collision.name = "WingTransition%d"%i
		collision.shape = BoxShape3D.new()
		collision.disabled = true
		bike.add_child(collision)
		transition_shapes.append(collision)
	rear_collision.setup(bike)
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
		if not bike.is_on_floor():
			last_rejection = "Deploy while driving on stable ground."
			return false
		if not clearance():
			last_rejection = "Move into open ground before deploying wings."
			return false
		mode = "DEPLOYING"
	mode_changed.emit(mode)
	return true

func advance(delta: float) -> void:
	# Preserve the established abort behavior when the final horizontal space
	# becomes obstructed. A blocked unfolding arc can instead wait in place.
	if mode=="DEPLOYING" and not clearance():
		mode = "FOLDING"
		last_rejection = "Wing space became blocked; folding safely."
		mode_changed.emit(mode)
	if mode in ["DEPLOYING","FOLDING"]:
		var previous := progress
		progress = move_toward(progress,1.0 if mode=="DEPLOYING" else 0.0,delta/1.1)
		_present()
		if not _partial_pose_clear(bike.visual.transform):
			progress = previous
			_present()
			_set_blocked(true)
		else:
			_set_blocked(false)
			if mode=="DEPLOYING" and progress>=1:
				mode = "AIRCRAFT"
				mode_changed.emit(mode)
			elif mode=="FOLDING" and progress<=0:
				mode = "BIKE"
				mode_changed.emit(mode)
	else:
		_set_blocked(false)
	_present()
	propeller.rotation.z += delta * absf(bike.speed)*1.5

func _set_blocked(value: bool) -> void:
	if value and not transition_blocked:
		last_rejection = "Wing movement blocked. Reverse into open ground to continue."
		bike.message.emit(last_rejection)
	transition_blocked = value

func _present() -> void:
	for i in range(pivots.size()):
		var side := -1.0 if i==0 else 1.0
		pivots[i].visible = progress>0.01
		pivots[i].rotation.z = side*(1.0-progress)*PI*0.46
		pivots[i].scale.x = maxf(0.05,progress)
	tail.visible = progress>0.05
	tail.scale = Vector3.ONE * maxf(0.05,progress)
	tail.position.y = AircraftTailCollision.ANCHOR_HEIGHT*(1-progress)
	wing_collision.disabled = mode != "AIRCRAFT"
	_sync_transition_shapes()
	rear_collision.sync(progress,mode!="BIKE")

func reset() -> void:
	transition_blocked = false
	progress = 0
	mode = "BIKE"
	_present()

func _wing_transform(visual_transform: Transform3D) -> Transform3D:
	return visual_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.55,0.05))

func _pose_clear(visual_transform: Transform3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = wing_collision.shape
	query.transform = bike.global_transform*_wing_transform(visual_transform)
	query.collision_mask = 1
	query.exclude = [bike.get_rid()]
	return bike.get_world_3d().direct_space_state.intersect_shape(query).is_empty() and rear_collision.clear(visual_transform,1.0)

func sync_wing_pose(previous_visual: Transform3D) -> void:
	# Do not rotate an already deployed rigid wing into nearby world geometry.
	if (mode=="AIRCRAFT" and not _pose_clear(bike.visual.transform)) or (mode in ["DEPLOYING","FOLDING"] and not _partial_pose_clear(bike.visual.transform)):
		bike.visual.transform = previous_visual
	wing_collision.transform = _wing_transform(bike.visual.transform)
	_sync_transition_shapes()
	rear_collision.sync(progress,mode!="BIKE")

func clearance() -> bool:
	return _pose_clear(bike.visual.transform)

func _transition_transform(index: int, visual_transform: Transform3D) -> Transform3D:
	var frame := visual_transform*pivots[index].transform
	var side := -1.0 if index==0 else 1.0
	return Transform3D(frame.basis.orthonormalized(),frame*Vector3(side*2.0,0,0))

func _sync_transition_shapes() -> void:
	for i in range(transition_shapes.size()):
		var collision := transition_shapes[i]
		collision.disabled = mode not in ["DEPLOYING","FOLDING"] or progress<=0.01
		var frame := bike.visual.transform*pivots[i].transform
		var size := Vector3(4.0,0.18,1.24)*frame.basis.get_scale().abs()
		if collision.shape.size!=size: collision.shape.size = size
		collision.transform = _transition_transform(i,bike.visual.transform)

func _partial_pose_clear(visual_transform: Transform3D) -> bool:
	if progress<=0.01: return true
	for i in range(transition_shapes.size()):
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = transition_shapes[i].shape
		query.transform = bike.global_transform*_transition_transform(i,visual_transform)
		query.collision_mask = 1
		query.exclude = [bike.get_rid()]
		if not bike.get_world_3d().direct_space_state.intersect_shape(query).is_empty(): return false
	return rear_collision.clear(visual_transform,progress)
