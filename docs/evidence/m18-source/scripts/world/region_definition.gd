class_name RegionDefinition
extends Resource
@export var id: String
@export var title: String
@export var biome: String
@export var center: Vector2
@export var accent: Color

func position_3d() -> Vector3:
	return Vector3(center.x,CoastalRegion.height_at(center.x,center.y),center.y)
