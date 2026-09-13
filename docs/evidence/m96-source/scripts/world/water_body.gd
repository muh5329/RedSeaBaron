class_name WaterBody
extends Resource
@export var title: String = "Coastal water"
@export var bounds := Rect2(-360,-550,1100,1100)
@export var level: float = -2.4
@export var elliptical: bool = false

func depth_at(at: Vector3) -> float:
	var point := Vector2(at.x,at.z)
	if not bounds.has_point(point): return 0
	if elliptical and ((point-bounds.get_center())/(bounds.size*0.5)).length_squared()>1:
		return 0
	return maxf(0,level-at.y)
