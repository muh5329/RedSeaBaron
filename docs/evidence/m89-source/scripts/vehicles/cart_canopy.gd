class_name CartCanopy
extends RefCounted
## One fixed curved cover; rendering and convex collision share this cross-section.
const HALF_WIDTH: float = 0.86
const HALF_LENGTH: float = 1.03
const EAVE_HEIGHT: float = 1.78
const RISE: float = 0.60
const SEGMENTS: int = 12
static var cloth: StandardMaterial3D

static func point(index: int, end: float) -> Vector3:
	var angle := -PI/2+PI*index/SEGMENTS
	return Vector3(HALF_WIDTH*sin(angle),EAVE_HEIGHT+RISE*cos(angle),end*HALF_LENGTH)

static func collision_points() -> PackedVector3Array:
	var points := PackedVector3Array()
	for i in range(SEGMENTS+1):
		for end in [-1.0,1.0]: points.append(point(i,end))
	for side in [-1.0,1.0]:
		for end in [-1.0,1.0]: points.append(Vector3(side*0.82,1.30,end*HALF_LENGTH))
	return points

static func build(parent: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(SEGMENTS):
		for corner in [[i,-1.0],[i+1,-1.0],[i,1.0],[i,1.0],[i+1,-1.0],[i+1,1.0]]:
			var angle: float = -PI/2+PI*int(corner[0])/SEGMENTS
			surface.set_normal(Vector3(sin(angle)/HALF_WIDTH,cos(angle)/RISE,0).normalized())
			surface.add_vertex(point(int(corner[0]),float(corner[1])))
	var cover := MeshInstance3D.new()
	cover.name = "ExpeditionCanopy"
	cover.mesh = surface.commit()
	if cloth==null:
		cloth = BlockoutKit.material(Color("d5c6a5")).duplicate()
		cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	cover.material_override = cloth
	parent.add_child(cover)
	for end in [-0.94,0.0,0.94]:
		for i in range(SEGMENTS):
			VehicleMesh.rod(parent,point(i,end)-Vector3.UP*0.018,point(i+1,end)-Vector3.UP*0.018,0.018,Color("b39358"))
	for side in [-1.0,1.0]:
		VehicleMesh.rod(parent,Vector3(side*0.84,1.78,-0.98),Vector3(side*0.84,1.78,0.98),0.028,Color("715d40"))
		for end in [-0.95,0.95]:
			VehicleMesh.rod(parent,Vector3(side*0.82,0.67,end),Vector3(side*0.84,1.80,end),0.038,Color("b39358"))
