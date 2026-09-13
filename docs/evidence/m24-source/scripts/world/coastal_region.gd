class_name CoastalRegion
extends Node3D
## Authored 320 m representative region, split into independent terrain tiles.
## Outer chunks and core activation are owned by WorldManager.
const SIZE: float = 320.0
const TILE: int = 64
const GRID: int = 4
var rng := RandomNumberGenerator.new()
var terrain_material: StandardMaterial3D
var merged_visuals: int = 0
var camera_obstacle: MeshInstance3D

static func height_at(x: float, z: float) -> float:
	var hills := (sin(x * 0.024) * cos(z * 0.028) + 1.0) * 2.0
	var upland := 8.0 * exp(-pow((x - 48.0) / 31.0, 2.0) - pow((z + 89.0) / 44.0, 2.0))
	var coastal_drop := smoothstep(70.0, 130.0, x) * 12.0
	var local := hills + upland - coastal_drop
	var blend := smoothstep(160.0,650.0,maxf(absf(x),absf(z)))
	var far := 25.0+sin(x*0.002)*cos(z*0.0017)*22.0+sin((x+z)*0.005)*4.0
	if z < -5000: far += smoothstep(-5000.0,-8500.0,z)*90.0
	return lerpf(local,far,blend)

func _ready() -> void:
	rng.seed = 1947
	_environment()
	_terrain()
	_roads()
	_village()
	_farm()
	_landmarks()
	_vegetation()
	_test_obstacles()
	merged_visuals = StaticBatcher.combine(self)

func _environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("679eaf")
	sky_material.sky_horizon_color = Color("d9d2b6")
	sky_material.ground_horizon_color = Color("d9d2b6")
	sky_material.ground_bottom_color = Color("7a8774")
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("bbcbd0")
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Color("a6bec0")
	env.fog_density = 0.0018
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -35, 0)
	sun.light_color = Color("fff0d6")
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	sun.shadow_bias = 0.15
	sun.shadow_normal_bias = 1.2
	sun.shadow_reverse_cull_face = true
	sun.directional_shadow_max_distance = 110.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)
	var ocean := PlaneMesh.new()
	ocean.size = Vector2(1100, 1100)
	var water := BlockoutKit.mesh(self, ocean, Vector3(190, -2.4, 0), Color("367e88"))
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode cull_disabled; void fragment(){float w=sin(VERTEX.x*0.6+TIME)*sin(VERTEX.z*0.3+TIME*0.7);ALBEDO=mix(vec3(0.11,0.32,0.38),vec3(0.25,0.56,0.57),w*0.5+0.5);ROUGHNESS=0.4;}"
	var water_material := ShaderMaterial.new()
	water_material.shader = shader
	water.material_override = water_material

func _terrain() -> void:
	terrain_material = StandardMaterial3D.new()
	terrain_material.vertex_color_use_as_albedo = true
	terrain_material.roughness = 1.0
	for tx in range(-2, 3):
		for tz in range(-2, 3):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for x in range(0, TILE, GRID):
				for z in range(0, TILE, GRID):
					var px := float(tx * TILE + x - 32)
					var pz := float(tz * TILE + z - 32)
					var a := Vector3(px, height_at(px, pz), pz)
					var b := Vector3(px + GRID, height_at(px + GRID, pz), pz)
					var c := Vector3(px, height_at(px, pz + GRID), pz + GRID)
					var d := Vector3(px + GRID, height_at(px + GRID, pz + GRID), pz + GRID)
					var col := Color("829065").lerp(Color("a9ab77"), rng.randf() * 0.65)
					if px > 75:
						col = Color("c1b186").lerp(Color("dec79e"), rng.randf() * 0.6)
					for point in [a, b, c, b, d, c]:
						surface.set_color(col)
						surface.add_vertex(point)
			surface.generate_normals()
			var tile := MeshInstance3D.new()
			tile.name = "Terrain_%s_%s" % [tx, tz]
			tile.mesh = surface.commit()
			tile.material_override = terrain_material
			add_child(tile)
			tile.create_trimesh_collision()

func _ribbon(points: Array[Vector2], width: float, color: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		var side := (b - a).normalized().orthogonal() * width * 0.5
		var coords := [a + side, b + side, a - side, b + side, b - side, a - side]
		for coord: Vector2 in coords:
			surface.add_vertex(Vector3(coord.x, height_at(coord.x, coord.y) + 0.085, coord.y))
	surface.generate_normals()
	var mat := BlockoutKit.material(color).duplicate() as StandardMaterial3D
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var path := MeshInstance3D.new()
	path.mesh = surface.commit()
	path.material_override = mat
	# Road overlays receive shadows, but cannot cast them onto their own terrain.
	path.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(path)

func _roads() -> void:
	var main_road: Array[Vector2] = []
	for z in range(65, -139, -3):
		main_road.append(Vector2(4 + sin(z * 0.018) * 10, z))
	_ribbon(main_road, 7.5, Color("c4aa7e"))
	var farm_road: Array[Vector2] = []
	for i in range(31):
		farm_road.append(Vector2(-float(i) * 1.8, -34.0 - float(i) * 0.8))
	_ribbon(farm_road, 4.0, Color("bea378"))
	var overlook: Array[Vector2] = []
	for i in range(36):
		overlook.append(Vector2(float(i) * 1.4, -67.0 - float(i) * 0.7))
	_ribbon(overlook, 3.5, Color("c5ae86"))
	var plaza := BlockoutKit.cylinder(self, Vector3(2, height_at(2, 2) + 0.015, 2), 12, 0.07, Color("c7b28b"), -1, 36)
	plaza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _building(at: Vector2, size: Vector3, color: Color, title: String) -> void:
	var root := Node3D.new()
	root.position = Vector3(at.x, height_at(at.x, at.y), at.y)
	add_child(root)
	BlockoutKit.box(root, Vector3(0, size.y * 0.5 - 0.2, 0), size + Vector3(0, 0.4, 0), color, true)
	BlockoutKit.box(root, Vector3(0, 0.18, 0), Vector3(size.x + 0.4, 0.36, size.z + 0.4), Color("817d65"), true)
	var roof := PrismMesh.new()
	roof.size = Vector3(size.x + 1.2, 2.8, size.z + 1.2)
	BlockoutKit.mesh(root, roof, Vector3(0, size.y + 1.3, 0), Color("9d5542"))
	BlockoutKit.box(root, Vector3(size.x * 0.28, size.y + 2.5, 0), Vector3(0.65, 2, 0.65), Color("e0c6a3"))
	var front := size.z * 0.5 + 0.04
	BlockoutKit.box(root, Vector3(0, 1.2, front), Vector3(1.3, 2.4, 0.16), Color("435f59"))
	for x in [-size.x * 0.33, size.x * 0.33]:
		BlockoutKit.box(root, Vector3(x, 2.25, front), Vector3(1.5, 1.55, 0.15), Color("6c4e39"))
		BlockoutKit.box(root, Vector3(x, 2.25, front + 0.1), Vector3(1.1, 1.2, 0.1), Color("304e50"))
		BlockoutKit.box(root, Vector3(x, 2.25, front + 0.2), Vector3(0.07, 1.2, 0.1), Color("d3b381"))
	if not title.is_empty():
		var signboard := BlockoutKit.box(root, Vector3(0, 3.55, front + 0.12), Vector3(4.8, 0.62, 0.20), Color("294a49"))
		BlockoutKit.label(signboard, title, Vector3(0, 0, 0.12), 26)

func _village() -> void:
	_building(Vector2(-13, -8), Vector3(10, 4.7, 8), Color("deca9f"), "THE SALT & SPANNER")
	_building(Vector2(17, -23), Vector3(11, 5.2, 9), Color("ddc6a4"), "BARON'S WORKSHOP")
	_building(Vector2(-16, -35), Vector3(7, 6, 7), Color("cdb996"), "")
	_building(Vector2(18, -53), Vector3(9, 4.4, 8), Color("d8c39c"), "POST & PROVISIONS")
	_building(Vector2(-25, 22), Vector3(8, 4.5, 7), Color("d0be98"), "")
	for i in range(5):
		var at := Vector3(-18 + i * 2, height_at(-18 + i * 2, -2) + 3.4, -2)
		BlockoutKit.box(self, at, Vector3(1.0, 0.1, 2.1), Color("b75440") if i % 2 == 0 else Color("e2d3aa"))
	for x in [-19, -9]:
		BlockoutKit.box(self, Vector3(x, height_at(x, -1) + 1.6, -1), Vector3(0.12, 3.2, 0.12), Color("776046"))
	for pos in [Vector2(9, 14), Vector2(-8, -22), Vector2(9, -42), Vector2(-4, -66)]:
		var base := Vector3(pos.x, height_at(pos.x, pos.y), pos.y)
		BlockoutKit.cylinder(self, base + Vector3.UP * 1.9, 0.09, 3.8, Color("45504a"))
		BlockoutKit.box(self, base + Vector3(0, 3.7, 0), Vector3(0.4, 0.58, 0.4), Color("f2ca7c"))
		BlockoutKit.cylinder(self, base + Vector3.UP * 4.08, 0.37, 0.25, Color("405149"), 0.02)
	# Fountain and benches establish a safe starting square.
	var center := Vector3(4, height_at(4, 4), 4)
	BlockoutKit.cylinder(self, center + Vector3.UP * 0.32, 2.3, 0.64, Color("a2a68c"), -1, 16)
	BlockoutKit.cylinder(self, center + Vector3.UP * 0.65, 1.95, 0.06, Color("4d8a8e"), -1, 16)
	BlockoutKit.cylinder(self, center + Vector3.UP, 0.28, 1.4, Color("c2bb99"))
	for i in range(12):
		var x := rng.randf_range(11, 24)
		var z := rng.randf_range(-15, -13)
		var h := rng.randf_range(0.45, 0.8)
		BlockoutKit.box(self, Vector3(x, height_at(x, z) + h * 0.5, z), Vector3(h, h, h), Color("a47b49"))

func _farm() -> void:
	_building(Vector2(-60, -72), Vector3(8, 4.4, 7), Color("cdbb94"), "OLIVE FARM")
	for row in range(7):
		var x := -66.0 + row * 2.7
		var line: Array[Vector2] = []
		for i in range(9):
			line.append(Vector2(x, -52.0 - i * 1.4))
		_ribbon(line, 1.65, Color("826647"))
		for j in range(8):
			var z := -52.0 - j * 1.5
			BlockoutKit.sphere(self, Vector3(x, height_at(x, z) + 0.35, z), Vector3(0.75, 0.45, 0.75), Color("657b48"))
	for i in range(13):
		var x := -71.0 + i * 2.2
		BlockoutKit.box(self, Vector3(x, height_at(x, -48) + 0.7, -48), Vector3(0.14, 1.4, 0.14), Color("917d59"))
		if i < 12:
			BlockoutKit.box(self, Vector3(x + 1.1, height_at(x, -48) + 1.0, -48), Vector3(2.3, 0.14, 0.14), Color("917d59"))

func _rock(at: Vector3, size: Vector3, color: Color, collision: bool = false) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for level in range(4):
		var points := PackedVector3Array()
		var heights: Array[float] = [-0.5, -0.15, 0.27, 0.5]
		var widths: Array[float] = [0.80, 1.0, 0.88, 0.62]
		for j in range(7):
			var angle := j * TAU / 7.0
			var width := widths[level] * rng.randf_range(0.86, 1.12) * 0.5
			points.append(Vector3(cos(angle) * width, heights[level], sin(angle) * width))
		rings.append(points)
	for level in range(3):
		for j in range(7):
			var next := (j + 1) % 7
			for v in [rings[level][j], rings[level + 1][j], rings[level][next], rings[level][next], rings[level + 1][j], rings[level + 1][next]]:
				surface.add_vertex(v)
	for j in range(7):
		for v in [Vector3(0, 0.5, 0), rings[3][(j + 1) % 7], rings[3][j]]:
			surface.add_vertex(v)
	surface.generate_normals()
	var item := BlockoutKit.mesh(self, surface.commit(), at, color)
	item.scale = size
	item.rotation.y = rng.randf() * TAU
	if collision:
		item.create_trimesh_collision()

func _landmarks() -> void:
	# Distant limestone spires and an arch echo the supplied coastal references.
	for i in range(21):
		var x := -145.0 + i * 13.0
		var z := -142.0 + sin(i * 1.7) * 8
		var h := rng.randf_range(25, 57)
		_rock(Vector3(x, height_at(x, z) + h * 0.27, z), Vector3(rng.randf_range(17, 29), h, rng.randf_range(16, 24)), Color("c9bd9f"), true)
		_rock(Vector3(x, height_at(x, z) + h * 0.77 + 0.5, z), Vector3(13, 4.5, 11), Color("5d7762"))
	for i in range(16):
		var z := -120.0 + i * 15.0
		var x := 95.0 + rng.randf_range(-7, 8)
		_rock(Vector3(x, height_at(x, z), z), Vector3(13, 15, 10), Color("d3c09b"), true)
	_rock(Vector3(62, 9, -123), Vector3(12, 29, 14), Color("d1c09e"), true)
	_rock(Vector3(88, 9, -123), Vector3(12, 30, 14), Color("cab999"), true)
	_rock(Vector3(75, 33, -123), Vector3(37, 8, 13), Color("d6c6a4"), true)
	var tower := Vector3(54, height_at(54, -95), -95)
	BlockoutKit.cylinder(self, tower + Vector3.UP * 4, 2.6, 8, Color("d2c19d"), 2.1, 12)
	BlockoutKit.cylinder(self, tower + Vector3.UP * 8.2, 3.0, 0.65, Color("947653"), -1, 12)
	BlockoutKit.cylinder(self, tower + Vector3.UP * 9.2, 1.5, 1.5, Color("3f6868"), -1, 12)
	BlockoutKit.cylinder(self, tower + Vector3.UP * 10.5, 2.4, 1.3, Color("a45740"), 0.05, 12)

func _multimesh(geometry: Mesh, transforms: Array[Transform3D], color: Color) -> void:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = geometry
	batch.instance_count = transforms.size()
	for i in range(transforms.size()):
		batch.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = batch
	node.material_override = BlockoutKit.material(color)
	add_child(node)

func _vegetation() -> void:
	var trunks: Array[Transform3D] = []
	var crowns: Array[Transform3D] = []
	var shrubs: Array[Transform3D] = []
	var grasses: Array[Transform3D] = []
	for i in range(620):
		var x := rng.randf_range(-142, 80)
		var z := rng.randf_range(-135, 145)
		# Keep settlement, trail junctions and survey route clear.
		if (absf(x) < 32 and z < 37 and z > -78) or (x < -35 and z < -42 and z > -80):
			continue
		if absf(z + 67 + x * 0.5) < 5:
			continue
		var base := Vector3(x, height_at(x, z), z)
		var size := rng.randf_range(0.7, 1.4)
		if i < 105:
			trunks.append(Transform3D(Basis.from_scale(Vector3(size, size, size)), base + Vector3.UP * size * 2.2))
			for j in range(3):
				crowns.append(Transform3D(Basis.from_scale(Vector3(3.6, 2.4, 3.6) * size), base + Vector3(rng.randf_range(-1.5, 1.5), 4.5 + j * 0.7, rng.randf_range(-1.3, 1.3)) * size))
		else:
			shrubs.append(Transform3D(Basis.from_scale(Vector3(1.2, 0.65, 1.1) * size), base + Vector3.UP * 0.5))
	for i in range(2300):
		var x := rng.randf_range(-144, 76)
		var z := rng.randf_range(-137, 144)
		if absf(x - (4 + sin(z * 0.018) * 10)) < 7 or (absf(x) < 32 and z < 32 and z > -78):
			continue
		grasses.append(Transform3D(Basis.from_scale(Vector3(0.25, rng.randf_range(0.25, 0.7), 0.25)), Vector3(x, height_at(x, z) + 0.12, z)))
	var trunk := CylinderMesh.new()
	trunk.bottom_radius = 0.21
	trunk.top_radius = 0.12
	trunk.height = 4.4
	trunk.radial_segments = 5
	_multimesh(trunk, trunks, Color("756047"))
	var foliage := SphereMesh.new()
	foliage.radial_segments = 7
	foliage.rings = 3
	_multimesh(foliage, crowns, Color("4d7160"))
	_multimesh(foliage, shrubs, Color("74844e"))
	var grass := PrismMesh.new()
	_multimesh(grass, grasses, Color("b8b883"))
	# Cypress silhouettes at the village entrance.
	for point in [Vector2(-9, 19), Vector2(15, 13), Vector2(-28, -26), Vector2(29, -45), Vector2(-48, -73)]:
		var base := Vector3(point.x, height_at(point.x, point.y), point.y)
		BlockoutKit.cylinder(self, base + Vector3.UP * 1.3, 0.21, 2.6, Color("706449"))
		BlockoutKit.sphere(self, base + Vector3.UP * 5.2, Vector3(2.1, 5.3, 2.1), Color("566c43"))

func _test_obstacles() -> void:
	# Traversal lane east of spawn: steps, vault-height jump and camera wall.
	for i in range(4):
		var at := Vector3(24 + i * 2, 0, 20)
		var h := 0.22 + i * 0.18
		at.y = height_at(at.x, at.z) + h * 0.5
		BlockoutKit.box(self, at, Vector3(1.5, h, 3), Color("b6aa89"), true)
	camera_obstacle = BlockoutKit.box(self, Vector3(37, height_at(37, 20) + 2, 20), Vector3(2, 4, 12), Color("cbbb98"), true)
