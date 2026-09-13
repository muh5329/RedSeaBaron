class_name RegionalTreeMesh
extends RefCounted
## One shared broadleaf mesh; all limbs and crowns stay in the existing batch.
static func append_to(surface: SurfaceTool) -> void:
	branch(surface,Vector3.ZERO,Vector3(0,2.7,0),0.27,0.16)
	branch(surface,Vector3(0,1.9,0),Vector3(-1.35,3.65,0.15),0.17,0.075)
	branch(surface,Vector3(0,2.1,0),Vector3(1.25,3.85,0.25),0.16,0.065)
	branch(surface,Vector3(0,2.35,0),Vector3(0.25,3.8,-1.15),0.13,0.06)
	var crowns := [
		[Vector3(0,4.25,0),Vector3(1.9,1.7,1.8),Color("6e8a50")],
		[Vector3(-1.55,3.65,0.1),Vector3(1.5,1.35,1.55),Color("607f49")],
		[Vector3(1.35,3.85,0.25),Vector3(1.55,1.35,1.45),Color("66854c")],
		[Vector3(0.25,3.6,-1.3),Vector3(1.55,1.3,1.4),Color("587346")],
		[Vector3(-0.3,3.45,1.25),Vector3(1.5,1.25,1.4),Color("607a47")]
	]
	for i in range(crowns.size()):
		var crown := SphereMesh.new()
		crown.radius = 1
		crown.height = 2
		crown.radial_segments = 8
		crown.rings = 4
		var pose := Transform3D(Basis(Vector3.UP,i*0.43).scaled(crowns[i][1]),crowns[i][0])
		append_primitive(surface,crown,pose,crowns[i][2])

static func branch(surface: SurfaceTool, from: Vector3, to: Vector3, lower: float, upper: float) -> void:
	var stem := CylinderMesh.new()
	stem.height = from.distance_to(to)
	stem.bottom_radius = lower
	stem.top_radius = upper
	stem.radial_segments = 6
	var direction := (to-from).normalized()
	append_primitive(surface,stem,Transform3D(Basis(Quaternion(Vector3.UP,direction)),(from+to)*0.5),Color("745942"))

static func append_primitive(surface: SurfaceTool, primitive: PrimitiveMesh, pose: Transform3D, color: Color) -> void:
	var arrays := primitive.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var normal_frame := pose.basis.inverse().transposed()
	for index in indices:
		surface.set_color(color)
		surface.set_normal((normal_frame*normals[index]).normalized())
		surface.add_vertex(pose*vertices[index])
