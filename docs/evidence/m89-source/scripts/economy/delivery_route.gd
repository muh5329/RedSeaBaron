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
	var forest := DeliveryRoute.new()
	forest.id = "greenreach"
	forest.title = "Greenreach timber camp"
	forest.point = Vector2(-3600,716)
	forest.reward = 500
	return [local,regional,forest]

static func next_id(current: String) -> String:
	var routes := catalog()
	for i in range(routes.size()):
		if routes[i].id==current: return routes[(i+1)%routes.size()].id
	return routes[0].id

static func valid_id(value: Variant) -> bool:
	return value is String and catalog().any(func(route): return route.id==value)
