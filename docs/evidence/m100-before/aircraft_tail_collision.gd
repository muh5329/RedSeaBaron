class_name AircraftTailCollision
extends RefCounted
## Separate tail and nose pieces avoid one oversized box around the aircraft.
const ANCHOR_HEIGHT: float = 1.16
const PARTS := [
	[Vector3(0,1.08,1.7),Vector3(0.18,0.18,1.9)],
	[Vector3(0,1.75,2.4),Vector3(0.20,1.55,0.85)],
	[Vector3(0,1.2,2.4),Vector3(2.3,0.18,0.8)],
	# A conservative box contains the propeller's complete rotating sweep.
	[Vector3(0,1.45,-1.9),Vector3(1.92,1.92,0.28)],
	[Vector3(0,1.375,-1.45),Vector3(0.18,0.32,0.9)]
]
var bike: BikeController
var shapes: Array[CollisionShape3D] = []
var probes: Array[BoxShape3D] = []

func setup(owner_bike: BikeController) -> void:
	bike = owner_bike
	for i in range(PARTS.size()):
		var shape := CollisionShape3D.new()
		shape.name = "AircraftTail%d"%i
		shape.shape = BoxShape3D.new()
		shape.disabled = true
		bike.add_child(shape)
		shapes.append(shape)
		probes.append(BoxShape3D.new())

func frame(index: int, visual: Transform3D, amount: float) -> Transform3D:
	var origin: Vector3 = Vector3(0,ANCHOR_HEIGHT*(1-amount),0)+PARTS[index][0]*amount
	return Transform3D(visual.basis,visual*origin)

func sync(amount: float, enabled: bool) -> void:
	for i in range(shapes.size()):
		var collision := shapes[i]
		collision.disabled = not enabled or amount<=0.05
		if collision.disabled: continue
		var box: BoxShape3D = collision.shape
		var size: Vector3 = PARTS[i][1]*amount
		if not box.size.is_equal_approx(size): box.size = size
		collision.transform = frame(i,bike.visual.transform,amount)

func clear(visual: Transform3D, amount: float) -> bool:
	if amount<=0.05: return true
	for i in range(shapes.size()):
		var size: Vector3 = PARTS[i][1]*amount
		if not probes[i].size.is_equal_approx(size): probes[i].size = size
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = probes[i]
		query.transform = bike.global_transform*frame(i,visual,amount)
		query.collision_mask = 1
		query.exclude = [bike.get_rid()]
		if not bike.get_world_3d().direct_space_state.intersect_shape(query).is_empty(): return false
	return true
