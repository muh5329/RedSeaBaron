class_name CartVisual
extends Node3D
## Reusable wooden cart presentation with a fixed eight-crate cargo pool.
var wheels: Array[Node3D] = []
var cargo: Node3D
var cargo_batches: Array[MultiMeshInstance3D] = []
const WOOD := Color("996943")
const FRAME := Color("596460")
const METAL := Color("b39358")

func _ready() -> void:
	for i in range(5):
		BlockoutKit.box(self,Vector3(-0.65+i*0.325,0.65,0),Vector3(0.30,0.16,2),WOOD)
	for side in [-1.0,1.0]:
		var x: float = side*0.80
		for i in range(3):
			BlockoutKit.box(self,Vector3(x,0.86+i*0.19,0),Vector3(0.10,0.16,2),WOOD.lightened(i*0.025))
		for z in [-0.93,0.93]:
			BlockoutKit.box(self,Vector3(x,1.03,z),Vector3(0.14,0.68,0.11),METAL)
			for y in [0.8,1.27]:
				var bolt := BlockoutKit.cylinder(self,Vector3(x+side*0.075,y,z),0.035,0.024,FRAME,-1,6)
				bolt.rotation.z = PI/2
		VehicleMesh.rod(self,Vector3(side*0.5,0.51,-1),Vector3(0,0.51,-2.32),0.055,METAL)
		VehicleMesh.rod(self,Vector3(side*0.6,0.49,-0.7),Vector3(side*0.6,0.49,0.85),0.06,FRAME)
		var wheel := VehicleMesh.wheel(self,Vector3(side*0.94,0.44,0.25),0.44,0.20,Color("293632"),FRAME,METAL)
		wheel.set_meta("animated_part",true)
		wheels.append(wheel)
		VehicleMesh.fender(self,Vector3(side*0.94,0.44,0.25),Color("a84e3d"),-1.15,1.15,0.49)
	for i in range(3):
		BlockoutKit.box(self,Vector3(0,0.86+i*0.19,0.94),Vector3(1.5,0.16,0.10),WOOD.lightened(i*0.025))
	VehicleMesh.rod(self,Vector3(-1.02,0.44,0.25),Vector3(1.02,0.44,0.25),0.065,FRAME)
	# A tied canvas roll suggests expedition equipment without adding a tall canopy collider.
	var canvas := BlockoutKit.cylinder(self,Vector3(0,1.22,0.77),0.14,1.25,Color("c8b995"),-1,12)
	canvas.rotation.z = PI/2
	for x in [-0.43,0.43]:
		var strap := BlockoutKit.cylinder(self,Vector3(x,1.22,0.77),0.147,0.055,Color("715d40"),-1,12)
		strap.rotation.z = PI/2
	StaticBatcher.combine(self)
	cargo = Node3D.new()
	cargo.name = "CargoCrates"
	add_child(cargo)
	_add_pool(Vector3(0.6,0.45,0.65),Color("c0925e"),Vector3.ZERO,1)
	_add_pool(Vector3(0.61,0.025,0.055),METAL,Vector3(0,0.232,0),2)
	_add_pool(Vector3(0.055,0.46,0.025),METAL,Vector3(0,0,-0.331),2)
	set_load(0)

func _add_pool(size: Vector3, color: Color, offset: Vector3, per_crate: int) -> void:
	var geometry := BoxMesh.new()
	geometry.size = size
	var node := MultiMeshInstance3D.new()
	var pool := MultiMesh.new()
	pool.transform_format = MultiMesh.TRANSFORM_3D
	pool.mesh = geometry
	pool.instance_count = 8*per_crate
	for i in range(8):
		var center := Vector3((i%2-0.5)*0.65,0.98+(i/4)*0.48,((i/2)%2-0.5)*0.7)
		for j in range(per_crate):
			var band := Vector3.ZERO
			if per_crate==2:
				band = Vector3(0,0,(j-0.5)*0.38) if offset.y>0 else Vector3((j-0.5)*0.34,0,0)
			pool.set_instance_transform(i*per_crate+j,Transform3D(Basis.IDENTITY,center+offset+band))
	node.multimesh = pool
	node.material_override = BlockoutKit.material(color)
	node.set_meta("per_crate",per_crate)
	cargo.add_child(node)
	cargo_batches.append(node)

func set_load(mass: float) -> void:
	var count := mini(8,ceili(mass/10.0))
	for batch in cargo_batches:
		batch.multimesh.visible_instance_count = count*int(batch.get_meta("per_crate"))
	cargo.visible = count>0

func animate_travel(distance: float) -> void:
	for wheel in wheels: wheel.rotation.x = fmod(wheel.rotation.x-distance/0.44,TAU)
