class_name RegionalBrook
extends RefCounted
## A bounded authored channel and one crossing, not a hydrology simulation.
const CENTER := Vector2(-600,-500)
const HALF_LENGTH: float = 200
const INNER_WIDTH: float = 8
const OUTER_WIDTH: float = 36
const END_BLEND: float = 48
const BOTTOM: float = 1
const LEVEL: float = 6
const WATER_WIDTH: float = 60
const DECK_HEIGHT: float = 10
static var body: WaterBody

static func carve(point: Vector2, height: float) -> float:
	var offset := (point-CENTER).abs()
	var across := smoothstep(INNER_WIDTH,OUTER_WIDTH,offset.x)
	var ends := smoothstep(HALF_LENGTH-END_BLEND,HALF_LENGTH+END_BLEND,offset.y)
	return lerpf(BOTTOM,height,maxf(across,ends))

static func water_body() -> WaterBody:
	if body==null:
		body = WaterBody.new()
		body.title = "Solis brook"
		body.bounds = Rect2(CENTER-Vector2(WATER_WIDTH/2,HALF_LENGTH+END_BLEND),Vector2(WATER_WIDTH,(HALF_LENGTH+END_BLEND)*2))
		body.level = LEVEL
	return body

static func crossing_height(x: float) -> float:
	# Deck joins the actual banks through gentle short approaches.
	var reach := absf(x-CENTER.x)
	var bank_x := CENTER.x+signf(x-CENTER.x)*56
	var bank := CoastalRegion.height_at(bank_x,CENTER.y)+0.08
	return lerpf(DECK_HEIGHT,bank,clampf((reach-24)/32,0,1))

static func clearing(point: Vector2) -> bool:
	return absf(point.x-CENTER.x)<62 and absf(point.y-CENTER.y)<9

static func build_bridge(chunk: Node3D) -> void:
	var root := Node3D.new()
	root.name = "BrookBridge"
	chunk.add_child(root)
	var wood := Color("866548")
	var stone := Color("a69e83")
	# A continuous surface avoids raised plank edges snagging small vehicle wheels.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-56,56,4):
		var x0 := CENTER.x+x
		var x1 := x0+4
		var a := Vector3(x0,crossing_height(x0),CENTER.y-3.5)
		var b := Vector3(x1,crossing_height(x1),CENTER.y-3.5)
		var c := Vector3(x0,crossing_height(x0),CENTER.y+3.5)
		var d := Vector3(x1,crossing_height(x1),CENTER.y+3.5)
		for vertex in [a,b,c,b,d,c]: surface.add_vertex(vertex)
	surface.generate_normals()
	BlockoutKit.mesh(root,surface.commit(),Vector3.ZERO,wood,true)
	for x in [-22,22]:
		for z in [-2.5,2.5]:
			BlockoutKit.box(root,Vector3(CENTER.x+x,5,CENTER.y+z),Vector3(2,9.6,1.8),stone,true)
	for z in [-3.65,3.65]:
		BlockoutKit.box(root,Vector3(CENTER.x,DECK_HEIGHT-0.4,CENTER.y+z),Vector3(48,0.8,0.45),wood,true)
		BlockoutKit.box(root,Vector3(CENTER.x,DECK_HEIGHT+0.65,CENTER.y+z),Vector3(48,1.3,0.25),wood,true)
		for x in range(-24,25,6):
			BlockoutKit.box(root,Vector3(CENTER.x+x,DECK_HEIGHT+0.8,CENTER.y+z),Vector3(0.3,1.6,0.3),Color("574e3d"))
	for x in [-52,52]:
		var y := crossing_height(CENTER.x+x)
		BlockoutKit.box(root,Vector3(CENTER.x+x,y+1.2,CENTER.y+5),Vector3(0.2,2.4,0.2),wood,true)
		BlockoutKit.box(root,Vector3(CENTER.x+x,y+2.2,CENTER.y+5),Vector3(3,0.65,0.2),Color("31554d"))
		BlockoutKit.label(root,"SOLIS BROOK",Vector3(CENTER.x+x,y+2.22,CENTER.y+5.12),24)
	StaticBatcher.combine(root)
