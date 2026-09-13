class_name QuarryAdit
extends RefCounted
## A short authored mine gallery, owned by its terrain chunk; terrain remains the floor.
const CENTER := Vector2(4829,1223)
const SOURCE := CENTER+Vector2(0,2)

static func position_3d() -> Vector3:
	return Vector3(CENTER.x,CoastalRegion.height_at(CENTER.x,CENTER.y),CENTER.y)

static func build(chunk: Node3D) -> void:
	var root := Node3D.new()
	root.name = "QuarryAdit"
	root.position = position_3d()
	chunk.add_child(root)
	var rock_body := StaticBody3D.new()
	rock_body.name = "RockCollision"
	root.add_child(rock_body)
	var rock := Color("a77c5c")
	for side in [-1,1]:
		BlockoutKit.box(root,Vector3(side*3.5,2.2,0),Vector3(1.5,6,9),rock,true)
		for step in range(3):
			var boulder := BlockoutKit.sphere(root,Vector3(side*4.2,1.2+step*0.65,-2+step*2),Vector3(2.2,2.7,2.3),rock.lightened(step*0.035))
			boulder.rotation.y = step*0.4
			_solid_rock(rock_body,boulder)
	BlockoutKit.box(root,Vector3(0,2.2,4),Vector3(7,6,1.5),rock,true)
	BlockoutKit.box(root,Vector3(0,4.9,0),Vector3(8,1.2,9),rock,true)
	for i in range(3):
		var crown := BlockoutKit.sphere(root,Vector3(-2.5+i*2.5,5.25,0.5),Vector3(3.2,1.5,4.5),rock.lightened(i*0.025))
		_solid_rock(rock_body,crown)
	# Broken rock edges cover the rectangular structural collision shell.
	for side in [-1,1]:
		for i in range(3):
			var edge := BlockoutKit.sphere(root,Vector3(side*(4.05+0.12*i),0.65+i*1.9,-4.15),Vector3(2.5,3.0,2.6),rock.lightened(0.025*i))
			edge.rotation = Vector3(0.12*i,side*0.35*i,side*0.08)
			_solid_rock(rock_body,edge)
	for i in range(3):
		var cap := BlockoutKit.sphere(root,Vector3(-2.7+i*2.7,5.45+0.15*(i%2),-4.2),Vector3(3.5,2.1,2.7),rock.lightened(0.045*i))
		cap.rotation.z = (i-1)*0.08
		_solid_rock(rock_body,cap)
	var timber := Color("69523d")
	for z in [-3.8,0.0,2.8]:
		for side in [-1,1]: BlockoutKit.box(root,Vector3(side*2.6,2.1,z),Vector3(0.28,4.2,0.3),timber,true)
		BlockoutKit.box(root,Vector3(0,4.15,z),Vector3(5.5,0.28,0.35),timber,true)
	for side in [-1,1]:
		BlockoutKit.box(root,Vector3(side*0.7,0.035,-0.5),Vector3(0.065,0.07,8),Color("706d61"))
	for z in [-4,-2.5,-1,0.5,2]: BlockoutKit.box(root,Vector3(0,0.02,z),Vector3(1.8,0.06,0.18),timber)
	BlockoutKit.box(root,Vector3(0,4.3,-4.6),Vector3(4.6,0.65,0.16),Color("394844"))
	BlockoutKit.label(root,"RED MESA · IRON WORKS",Vector3(0,4.32,-4.70),24).rotation.y = PI
	# A small warm work light keeps the shallow interior readable in Compatibility.
	var light := OmniLight3D.new()
	light.position = Vector3(0,3.4,0)
	light.light_color = Color("ffd496")
	light.light_energy = 0.65
	light.omni_range = 8
	light.shadow_enabled = false
	root.add_child(light)
	BlockoutKit.sphere(root,light.position,Vector3(0.16,0.22,0.16),Color("f2c67c"))
	StaticBatcher.combine(root)

static func _solid_rock(body: StaticBody3D, rock: MeshInstance3D) -> void:
	# Bake scale/rotation into convex points so the physics body stays unscaled.
	var primitive: PrimitiveMesh = rock.mesh
	var vertices: PackedVector3Array = primitive.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	var points := PackedVector3Array()
	for vertex in vertices: points.append(rock.transform*vertex)
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
