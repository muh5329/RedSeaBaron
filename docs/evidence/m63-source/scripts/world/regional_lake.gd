class_name RegionalLake
extends RefCounted
## One authored inland basin; CPU terrain and horizon receive the same parameters.
const CENTER := Vector2(620,1150)
const INNER_RADIUS: float = 50
const OUTER_RADIUS: float = 110
const BOTTOM: float = 8
const LEVEL: float = 14
const WATER_RADIUS: float = 90
static var body: WaterBody

static func carve(point: Vector2, height: float) -> float:
	return lerpf(BOTTOM,height,smoothstep(INNER_RADIUS,OUTER_RADIUS,point.distance_to(CENTER)))

static func water_body() -> WaterBody:
	if body==null:
		body = WaterBody.new()
		body.title = "Willowmere lake"
		body.bounds = Rect2(CENTER-Vector2.ONE*WATER_RADIUS,Vector2.ONE*WATER_RADIUS*2)
		body.level = LEVEL
		body.elliptical = true
	return body
