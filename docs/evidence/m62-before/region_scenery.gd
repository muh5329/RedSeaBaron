class_name RegionScenery
extends RefCounted
## Deterministic, chunk-owned decoration. Shared meshes; no per-plant physics.
static var meshes: Dictionary = {}
static var material: StandardMaterial3D
static var foliage_material: ShaderMaterial

static func _append(surface: SurfaceTool, primitive: PrimitiveMesh, at: Vector3, color: Color) -> void:
	var arrays := primitive.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index in indices:
		surface.set_color(color)
		surface.set_normal(normals[index])
		surface.add_vertex(vertices[index]+at)

static func model(kind: String) -> ArrayMesh:
	if meshes.has(kind): return meshes[kind]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if kind in ["tree","pine"]:
		var trunk := CylinderMesh.new()
		trunk.height = 3
		trunk.bottom_radius = 0.25
		trunk.top_radius = 0.15
		trunk.radial_segments = 6
		_append(surface,trunk,Vector3(0,1.5,0),Color("745942"))
		if kind=="pine":
			for level in range(3):
				var crown := CylinderMesh.new()
				crown.height = 2.7
				crown.bottom_radius = 1.8-level*0.35
				crown.top_radius = 0
				crown.radial_segments = 7
				_append(surface,crown,Vector3(0,2.8+level*1.25,0),Color("41665a").lightened(level*0.08))
		else:
			var crown := SphereMesh.new()
			crown.radius = 2.1
			crown.height = 3.8
			crown.radial_segments = 8
			crown.rings = 4
			_append(surface,crown,Vector3(0,4,0),Color("69844e"))
	elif kind=="rock":
		var rock := SphereMesh.new()
		rock.radius = 1.1
		rock.height = 1.6
		rock.radial_segments = 6
		rock.rings = 3
		_append(surface,rock,Vector3(0,0.55,0),Color("aaa58f"))
	else:
		for angle in [0,PI/3,PI*2/3]:
			for vertex in [Vector3(-0.35,0,0),Vector3(0,0.65,0),Vector3(0.35,0,0)]:
				surface.set_color(Color("b2ad70"))
				surface.set_normal(Vector3.FORWARD.rotated(Vector3.UP,angle))
				surface.add_vertex(vertex.rotated(Vector3.UP,angle))
	meshes[kind] = surface.commit()
	return meshes[kind]

static func populate(chunk: Node3D, coordinate: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(coordinate.x*73856093 ^ coordinate.y*19349663 ^ 1947)
	var origin := Vector2(coordinate)*64-Vector2.ONE*32
	var biome := RegionCatalog.biome_at(origin+Vector2.ONE*32)
	var counts: Dictionary
	match biome:
		"Forest": counts = {"tree":22,"rock":6,"grass":24}
		"Drylands": counts = {"rock":16,"grass":10}
		"Highlands": counts = {"pine":5,"rock":12}
		_: counts = {"tree":5,"rock":5,"grass":24}
	if material==null:
		material = StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = 1
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		foliage_material = FoliageFade.material(Color.WHITE,true)
	for kind: String in counts:
		var transforms: Array[Transform3D] = []
		for i in range(counts[kind]):
			var at := origin+Vector2(rng.randf_range(2,62),rng.randf_range(2,62))
			var ground := CoastalRegion.height_at(at.x,at.y)
			var clearing := false
			for region in RegionCatalog.all():
				if at.distance_to(region.center)<45: clearing = true
			if ground < -1.8 or clearing or RegionalLake.water_body().depth_at(Vector3(at.x,ground,at.y))>0: continue
			var scale := rng.randf_range(0.7,1.3)
			var basis := Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale)
			transforms.append(Transform3D(basis,Vector3(at.x,ground,at.y)))
		if transforms.is_empty(): continue
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = model(kind)
		multimesh.instance_count = transforms.size()
		for i in range(transforms.size()): multimesh.set_instance_transform(i,transforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.name = "Scenery_"+kind
		instance.multimesh = multimesh
		instance.material_override = foliage_material if kind in ["tree","pine"] else material
		instance.visibility_range_end = 200
		chunk.add_child(instance)
	for region in RegionCatalog.all():
		if WorldStreamer.coordinate(region.position_3d())==coordinate: landmark(chunk,region)

	if WorldStreamer.coordinate(QuarryAdit.position_3d())==coordinate: QuarryAdit.build(chunk)

static func landmark(chunk: Node3D, region: RegionDefinition) -> void:
	var root := Node3D.new()
	root.name = "Landmark_"+region.id
	root.position = region.position_3d()
	chunk.add_child(root)
	BlockoutKit.box(root,Vector3(0,0.15,0),Vector3(12,0.3,10),Color("b7a27f"))
	if region.biome=="Highlands":
		BlockoutKit.box(root,Vector3(0,5,0),Vector3(4,10,4),Color("929c98"),true)
		BlockoutKit.box(root,Vector3(0,10.3,0),Vector3(5.5,0.6,5.5),Color("d1d5ca"))
		BlockoutKit.cylinder(root,Vector3(0,11.5,0),0.7,2,Color("ce9749"))
	else:
		for x in [-4,4]:
			for z in [-3,3]: BlockoutKit.box(root,Vector3(x,2,z),Vector3(0.35,4,0.35),Color("79604b"),true)
		var roof := PrismMesh.new()
		roof.size = Vector3(9.5,2,7.5)
		BlockoutKit.mesh(root,roof,Vector3(0,4.6,0),region.accent)
		for i in range(5):
			BlockoutKit.box(root,Vector3(-3+i*1.4,0.8,-1),Vector3(1.1,1.3,1.4),Color("98754f") if region.biome!="Drylands" else Color("856b5c"))
		if region.biome=="Grassland":
			for i in range(5): BlockoutKit.box(root,Vector3(-4+i*2,0.1,8),Vector3(0.8,0.2,6),Color("7d8e54"))
		if region.biome=="Forest":
			# Timber stockpiles and a cutting bench distinguish the working camp.
			for level in range(3):
				for column in range(4-level):
					var log := BlockoutKit.cylinder(root,Vector3(-9+column*0.75+level*0.37,0.42+level*0.64,-1),0.40,6,Color("795b40"),-1,8)
					log.rotation.x = PI/2
					for end in [-3.01,3.01]:
						var grain := BlockoutKit.cylinder(root,Vector3(log.position.x,log.position.y,-1+end),0.31,0.035,Color("c49c67"),-1,8)
						grain.rotation.x = PI/2
			BlockoutKit.box(root,Vector3(7,0.9,0),Vector3(3,0.2,1.2),Color("91704c"),true)
			for x in [5.9,8.1]:
				BlockoutKit.box(root,Vector3(x,0.4,0),Vector3(0.25,0.8,0.8),Color("6c6554"))
	BlockoutKit.box(root,Vector3(0,2.1,6),Vector3(0.18,4.2,0.18),Color("705e4b"))
	BlockoutKit.box(root,Vector3(0,3.2,6),Vector3(6,0.8,0.2),Color("31554d"))
	BlockoutKit.label(root,region.title,Vector3(0,3.25,6.13),36)
	StaticBatcher.combine(root)
