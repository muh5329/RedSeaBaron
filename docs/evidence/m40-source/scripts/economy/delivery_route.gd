class_name DeliveryRoute
extends Resource
@export var id: String = "south_quay"
@export var title: String = "South quay"
@export var point := Vector2(39,67)
@export var reward: int = 75

static func catalog() -> Array[DeliveryRoute]:
	var local := DeliveryRoute.new()
	var regional := DeliveryRoute.new()
	regional.id = "longfield"
	regional.title = "Longfield waystation"
	regional.point = Vector2(900,1116)
	regional.reward = 180
	return [local,regional]

static func valid_id(value: Variant) -> bool:
	return value is String and value in ["south_quay","longfield"]
