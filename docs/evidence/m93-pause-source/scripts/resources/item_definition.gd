class_name ItemDefinition
extends Resource
@export var id: String = ""
@export var title: String = ""
@export var mass: float = 1
@export var value: int = 1
static var catalog: Dictionary = {}

static func get_item(key: String) -> ItemDefinition:
	if catalog.is_empty():
		for entry in [["olive","Olives",1.0,4],["ore","Iron ore",4.0,8],["wood","Timber",2.0,5],["package","Sealed parcel",8.0,0]]:
			var item := ItemDefinition.new()
			item.id = entry[0]
			item.title = entry[1]
			item.mass = entry[2]
			item.value = entry[3]
			catalog[item.id] = item
	return catalog.get(key)
