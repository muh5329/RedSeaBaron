class_name BlockoutKit
extends RefCounted
## Small shared mesh factory. Static shapes are opt-in; scenery has no process ticks.
static var materials: Dictionary = {}

static func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if materials.has(key):
		return materials[key]
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.94
	materials[key] = result
	return result

static func mesh(parent: Node3D, geometry: Mesh, at: Vector3, color: Color, collision: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = geometry
	node.material_override = material(color)
	node.position = at
	parent.add_child(node)
	if collision:
		node.create_trimesh_collision()
	return node

static func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, collision: bool = false) -> MeshInstance3D:
	var geometry := BoxMesh.new()
	geometry.size = size
	var result := mesh(parent, geometry, at, color, false)
	if collision:
		var body := StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		result.add_child(body)
		body.add_child(collider)
	return result

static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color, top: float = -1.0, sides: int = 10) -> MeshInstance3D:
	var geometry := CylinderMesh.new()
	geometry.bottom_radius = radius
	geometry.top_radius = radius if top < 0.0 else top
	geometry.height = height
	geometry.radial_segments = sides
	return mesh(parent, geometry, at, color)

static func sphere(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var geometry := SphereMesh.new()
	geometry.radial_segments = 8
	geometry.rings = 4
	var result := mesh(parent, geometry, at, color)
	result.scale = size
	return result

static func label(parent: Node3D, caption: String, at: Vector3, size: int = 40) -> Label3D:
	var result := Label3D.new()
	result.text = caption
	result.position = at
	result.font_size = size
	result.pixel_size = 0.008
	result.modulate = Color("f5e4bd")
	result.outline_modulate = Color("263b39")
	result.outline_size = 7
	parent.add_child(result)
	return result
