class_name VehicleMesh
extends RefCounted
## Procedural mechanical parts. No collision or processing; rigid groups are batched.
static func rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var result := BlockoutKit.cylinder(parent,(a+b)*0.5,radius,a.distance_to(b),color,-1,8)
	result.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	return result

static func ring(parent: Node3D, at: Vector3, inner: float, outer: float, width: float, color: Color) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = inner
	torus.outer_radius = outer
	torus.rings = 20
	torus.ring_segments = 8
	var result := BlockoutKit.mesh(parent,torus,at,color)
	result.rotation.z = PI/2
	result.scale.y = width/(outer-inner)
	return result

static func tank(parent: Node3D, at: Vector3, color: Color) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := PackedVector2Array([Vector2(-0.7,1),Vector2(0.7,1),Vector2(1,0.5),Vector2(1,-0.5),Vector2(0.7,-1),Vector2(-0.7,-1),Vector2(-1,-0.5),Vector2(-1,0.5)])
	var rings: Array[PackedVector3Array] = []
	for pair in [Vector2(-0.43,0.65),Vector2(-0.28,1),Vector2(0.23,1),Vector2(0.4,0.7)]:
		var vertices := PackedVector3Array()
		for point in points: vertices.append(Vector3(point.x*0.34*pair.y,point.y*0.21*pair.y,pair.x))
		rings.append(vertices)
	for r in range(3):
		for i in range(8):
			var j := (i+1)%8
			for vertex in [rings[r][i],rings[r+1][j],rings[r+1][i],rings[r][i],rings[r][j],rings[r+1][j]]: surface.add_vertex(vertex)
	for i in range(1,7):
		for vertex in [rings[0][0],rings[0][i+1],rings[0][i],rings[3][0],rings[3][i],rings[3][i+1]]: surface.add_vertex(vertex)
	surface.generate_normals()
	return BlockoutKit.mesh(parent,surface.commit(),at,color)

static func fender(parent: Node3D, center: Vector3, color: Color, start: float, end: float) -> void:
	# Short overlapping curved strips make a readable faceted steel mudguard.
	for i in range(10):
		var angle := lerpf(start,end,(i+0.5)/10.0)
		var strip := BlockoutKit.box(parent,center+Vector3(0,cos(angle)*0.54,sin(angle)*0.54),Vector3(0.31,0.045,0.54*(end-start)/10.0+0.025),color)
		strip.rotation.x = angle
