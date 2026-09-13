class_name RegionManager
extends Node
signal discovered_region(region: RegionDefinition)
var actor: PlayerController
var enabled: bool = false
var discovered: Dictionary = {}
var timer: float = 0

func _process(delta: float) -> void:
	if not enabled: return
	timer -= delta
	if timer>0: return
	timer = 0.5
	for region in RegionCatalog.all():
		if not discovered.get(region.id,false) and actor.position.distance_to(region.position_3d())<35:
			discovered[region.id] = true
			discovered_region.emit(region)

static func valid_record(record: Variant) -> bool:
	if not record is Dictionary: return false
	var ids := RegionCatalog.all().map(func(r): return r.id)
	for key in record:
		if key not in ids or not record[key] is bool: return false
	return true
