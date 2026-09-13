class_name FieldMap
extends Control
signal waypoint_selected(point: Vector3)
var player: PlayerController
var logistics: LogisticsWorld
var regions: RegionManager
var sites: Array[SurveySite] = []
var world_view: bool = false
var waypoint: Variant = null
const SIZE := Vector2(510,390)

func _ready() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true

func point(at: Vector3) -> Vector2:
	return SIZE/2+Vector2(at.x,at.z)*(0.014 if world_view else 1.1)

func mark(at: Vector3, caption: String, color: Color, radius: float = 5) -> void:
	var p := point(at)
	draw_circle(p,radius,color)
	draw_string(ThemeDB.fallback_font,p+Vector2(9,4),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("122c2a"))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,SIZE),Color("a8b091"))
	if world_view:
		draw_rect(Rect2(80,20,140,350),Color("7d947c"))
		draw_rect(Rect2(311,20,119,350),Color("cab085"))
		draw_rect(Rect2(80,20,350,105),Color("ced3c6"))
		for x in range(80,431,70): draw_line(Vector2(x,20),Vector2(x,370),Color("91a28e"),1)
		for y in range(20,371,70): draw_line(Vector2(80,y),Vector2(430,y),Color("91a28e"),1)
		mark(Vector3.ZERO,"Port Solis",Color("315e59"),6)
		var offsets := {"greenreach":Vector2(-107,22),"red_mesa":Vector2(12,5),"snowwatch":Vector2(-36,-12),"longfield":Vector2(12,28)}
		for region in RegionCatalog.all():
			var p := point(region.position_3d())
			draw_circle(p,4,Color("f7e5b8") if regions and regions.discovered.get(region.id,false) else region.accent)
			if not region.hostile_kinds.is_empty(): draw_arc(p,7,0,TAU,16,Color("a34d3e"),2)
			draw_string(ThemeDB.fallback_font,p+offsets[region.id],region.title.split(" ")[0],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("263e37"))
		draw_string(ThemeDB.fallback_font,Vector2(90,45),"HIGHLANDS",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("3d5550"))
		draw_string(ThemeDB.fallback_font,Vector2(88,350),"25 km × 25 km terrain domain",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("3d5550"))
	else:
		draw_rect(Rect2(355,0,155,390),Color("729b9c"))
		for z in range(-140,98,4):
			var a := Vector3(4+sin(z*0.018)*10,0,z)
			var b := Vector3(4+sin((z+4)*0.018)*10,0,z+4)
			draw_line(point(a),point(b),Color("e6cf9f"),5)
		draw_line(point(Vector3(0,0,-34)),point(Vector3(-54,0,-58)),Color("e6cf9f"),3)
		draw_line(point(Vector3(0,0,-67)),point(Vector3(49,0,-91)),Color("e6cf9f"),3)
		mark(Vector3(0,0,0),"Port Solis · trade",Color("315e59"),7)
		mark(Vector3(-48,0,-48),"Olive farm",Color("658143"))
		mark(Vector3(61,0,29),"Iron outcrop",Color("666d6b"))
		mark(Vector3(-27,0,53),"Timber",Color("846443"))
		mark(Vector3(39,0,67),"Quay · delivery",Color("ac6a39"))
		mark(Vector3(48,0,-91),"Lookout",Color("d1a35e"))
		mark(Vector3(-68,0,10),"Hostile camp",Color("ab4b3d"))
	if logistics and logistics.contract.state=="IN_TRANSIT":
		var delivery := point(logistics.contract.destination.position)
		draw_arc(delivery,10,0,TAU,24,Color("c77834"),3,true)
		if player and world_view: draw_line(point(player.position),delivery,Color("b27642"),2,true)
	if waypoint!=null:
		var p := point(waypoint)
		draw_arc(p,9,0,TAU,24,Color("fff0bb"),2,true)
		draw_line(p-Vector2(12,0),p+Vector2(12,0),Color("fff0bb"),1)
		draw_line(p-Vector2(0,12),p+Vector2(0,12),Color("fff0bb"),1)
	if player:
		var p := point(player.position)
		draw_circle(p,5,Color("fff6d6"))
		draw_arc(p,6,0,TAU,16,Color("263f39"),1,true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var coord: Vector2 = (event.position-SIZE/2)/(0.014 if world_view else 1.1)
		coord = coord.clamp(Vector2.ONE*-12500,Vector2.ONE*12500)
		waypoint = Vector3(coord.x,CoastalRegion.height_at(coord.x,coord.y),coord.y)
		waypoint_selected.emit(waypoint)
		queue_redraw()
