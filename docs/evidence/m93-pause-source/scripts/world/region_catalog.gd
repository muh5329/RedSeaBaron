class_name RegionCatalog
extends RefCounted
static var _regions: Array[RegionDefinition] = []

static func all() -> Array[RegionDefinition]:
	if _regions.is_empty():
		for row in [["greenreach","Greenreach timber camp","Forest",Vector2(-3600,700),Color("587a55")],["red_mesa","Red Mesa quarry","Drylands",Vector2(4800,1200),Color("bb7956")],["snowwatch","Snowwatch tower","Highlands",Vector2(-1060,-10000),Color("8ba9b2")],["longfield","Longfield waystation","Grassland",Vector2(900,1100),Color("b6a15c")]]:
			var region := RegionDefinition.new()
			region.id = row[0]
			region.title = row[1]
			region.biome = row[2]
			region.center = row[3]
			region.accent = row[4]
			if region.id=="red_mesa": region.hostile_kinds.assign(["Raider","Cinder beast"])
			if region.id=="snowwatch": region.hostile_kinds.assign(["Cinder beast"])
			_regions.append(region)
	return _regions

static func biome_at(point: Vector2) -> String:
	if point.y < -5000: return "Highlands"
	if point.x > 4000: return "Drylands"
	if point.x < -3000: return "Forest"
	return "Grassland"
