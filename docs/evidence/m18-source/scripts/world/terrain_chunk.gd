class_name TerrainChunk
extends Node3D
const SIZE: int = 64
const STEP: int = 8
var coordinate := Vector2i.ZERO

func build(at: Vector2i) -> void:
	coordinate = at
	name = "Stream_%d_%d"%[at.x,at.y]
	var origin := Vector2(at)*SIZE-Vector2.ONE*32
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(0,SIZE,STEP):
		for z in range(0,SIZE,STEP):
			var px := origin.x+x
			var pz := origin.y+z
			var color := biome_color(px,pz)
			for coord in [Vector2(px,pz),Vector2(px+STEP,pz),Vector2(px,pz+STEP),Vector2(px+STEP,pz),Vector2(px+STEP,pz+STEP),Vector2(px,pz+STEP)]:
				surface.set_color(color)
				surface.add_vertex(Vector3(coord.x,CoastalRegion.height_at(coord.x,coord.y),coord.y))
	surface.generate_normals()
	var geometry := MeshInstance3D.new()
	geometry.mesh = surface.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1
	geometry.material_override = mat
	add_child(geometry)
	geometry.create_trimesh_collision()
	RegionScenery.populate(self,at)

static func biome_color(x: float, z: float) -> Color:
	if z < -5000: return Color("c8d0cd")
	if x > 4000: return Color("c4a173")
	if x < -3000: return Color("526e58")
	return Color("91a16e")
