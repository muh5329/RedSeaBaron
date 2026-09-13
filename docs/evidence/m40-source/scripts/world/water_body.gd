class_name WaterBody
extends Resource
@export var title: String = "Coastal water"
@export var bounds := Rect2(-360,-550,1100,1100)
@export var level: float = -2.4

func depth_at(at: Vector3) -> float:
	return maxf(0,level-at.y) if bounds.has_point(Vector2(at.x,at.z)) else 0.0
