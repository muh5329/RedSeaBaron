class_name FieldMap
extends Control
signal waypoint_selected(point: Vector3)
signal waypoint_cleared
var bike: BikeController
var cart: CargoCart
var workers: WorkerManager
var tracking_active: bool = false
var tracking_checkpoint: bool = false
var tracked_asset: Node3D
var waypoint_title: String = "Waypoint"
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

func _track(target: Node3D, title: String) -> bool:
	if not is_instance_valid(target): return false
	tracking_checkpoint = false
	tracked_asset = target
	tracking_active = true
	waypoint_title = title
	world_view = absf(target.global_position.x)>160 or absf(target.global_position.z)>160
	waypoint = target.global_position
	waypoint_selected.emit(waypoint)
	queue_redraw()
	return true

func track_checkpoint() -> bool:
	if not is_instance_valid(player): return false
	tracked_asset = null
	tracking_active = true
	tracking_checkpoint = true
	waypoint_title = "Recovery checkpoint"
	waypoint = player.spawn_position
	world_view = absf(waypoint.x)>160 or absf(waypoint.z)>160
	waypoint_selected.emit(waypoint)
	queue_redraw()
	return true

func track_asset(kind: String) -> bool:
	var target: Node3D = bike if kind=="bike" else cart if kind=="cart" else null
	return _track(target,"Motorcycle" if kind=="bike" else "Cargo cart")

func track_worker(id: String) -> bool:
	if workers==null: return false
	var worker := workers.worker_by_id(id)
	if not is_instance_valid(worker): return false
	return _track(worker,worker.worker_name)

func refresh_tracking() -> void:
	if not tracking_active: return
	if tracking_checkpoint:
		if not is_instance_valid(player): clear_waypoint()
		elif waypoint!=player.spawn_position: track_checkpoint()
		return
	if not is_instance_valid(tracked_asset):
		clear_waypoint()
		return
	if tracked_asset is WorkerActor and (workers==null or not workers.workers.has(tracked_asset)):
		clear_waypoint()
		return
	if waypoint!=tracked_asset.global_position:
		waypoint = tracked_asset.global_position
		waypoint_selected.emit(waypoint)

func clear_waypoint() -> void:
	tracking_active = false
	tracking_checkpoint = false
	tracked_asset = null
	waypoint = null
	waypoint_title = "Waypoint"
	waypoint_cleared.emit()
	queue_redraw()

func _asset_marker(target: Node3D, color: Color, square: bool) -> void:
	if not is_instance_valid(target): return
	var at := point(target.global_position)
	if not Rect2(Vector2.ZERO,SIZE).grow(-8).has_point(at): return
	if square:
		draw_rect(Rect2(at-Vector2.ONE*5,Vector2.ONE*10),Color("233e37"))
		draw_rect(Rect2(at-Vector2.ONE*3,Vector2.ONE*6),color)
	else:
		draw_circle(at,6,Color("233e37"))
		draw_circle(at,4,color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,SIZE),Color("a8b091"))
	if world_view:
		draw_rect(Rect2(80,20,140,350),Color("7d947c"))
		draw_rect(Rect2(311,20,119,350),Color("cab085"))
		draw_rect(Rect2(80,20,350,105),Color("ced3c6"))
		for x in range(80,431,70): draw_line(Vector2(x,20),Vector2(x,370),Color("91a28e"),1)
		for y in range(20,371,70): draw_line(Vector2(80,y),Vector2(430,y),Color("91a28e"),1)
		mark(Vector3.ZERO,"Port Solis",Color("315e59"),6)
		var brook := point(Vector3(RegionalBrook.CENTER.x,0,RegionalBrook.CENTER.y))
		draw_line(brook+Vector2(0,-3),brook+Vector2(0,3),Color("438a9a"),2)
		draw_line(brook,brook+Vector2(-50,-18),Color("438a9a"),1)
		draw_string(ThemeDB.fallback_font,brook+Vector2(-105,-22),"Solis brook",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("263e37"))
		var lake := point(Vector3(RegionalLake.CENTER.x,RegionalLake.LEVEL,RegionalLake.CENTER.y))
		draw_circle(lake,3,Color("438a9a"))
		draw_line(lake,lake+Vector2(-22,-10),Color("438a9a"),1)
		draw_string(ThemeDB.fallback_font,lake+Vector2(-100,-14),"Willowmere",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("263e37"))
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
	_asset_marker(bike,Color("ba5641"),false)
	_asset_marker(cart,Color("e6c579"),true)
	if workers:
		for i in range(workers.workers.size()):
			var worker := workers.workers[i]
			if not is_instance_valid(worker): continue
			var at := point(worker.global_position)
			if not Rect2(Vector2.ZERO,SIZE).grow(-8).has_point(at): continue
			var diamond := PackedVector2Array([at+Vector2(0,-5),at+Vector2(5,0),at+Vector2(0,5),at+Vector2(-5,0)])
			draw_colored_polygon(diamond,worker.coat_color.lightened(0.2))
			draw_polyline(PackedVector2Array([diamond[0],diamond[1],diamond[2],diamond[3],diamond[0]]),Color("233e37"),1)
			draw_string(ThemeDB.fallback_font,at+Vector2(8,-7 if i%2==0 else 15),worker.worker_name,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("122c2a"))
	if waypoint!=null:
		var p := point(waypoint)
		draw_arc(p,9,0,TAU,24,Color("fff0bb"),2,true)
		draw_line(p-Vector2(12,0),p+Vector2(12,0),Color("fff0bb"),1)
		draw_line(p-Vector2(0,12),p+Vector2(0,12),Color("fff0bb"),1)
	if player:
		var checkpoint := point(player.spawn_position)
		if Rect2(Vector2.ZERO,SIZE).grow(-10).has_point(checkpoint):
			draw_arc(checkpoint,9,0,TAU,24,Color("315e59"),3,true)
			draw_arc(checkpoint,11,0,TAU,24,Color("f7e5b8"),1,true)
		var p := point(player.position)
		draw_circle(p,5,Color("fff6d6"))
		draw_arc(p,6,0,TAU,16,Color("263f39"),1,true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var closest: Node3D
		var threshold: float = 9.0
		var targets: Array[Node3D] = [bike,cart]
		if workers:
			for worker in workers.workers: targets.append(worker)
		for target: Node3D in targets:
			if is_instance_valid(target):
				var distance := point(target.global_position).distance_to(event.position)
				if distance<threshold:
					closest = target
					threshold = distance
		if closest!=null:
			if closest is WorkerActor: track_worker(closest.worker_id)
			else: track_asset("bike" if closest==bike else "cart")
			return
		tracked_asset = null
		tracking_active = false
		tracking_checkpoint = false
		waypoint_title = "Waypoint"
		var coord: Vector2 = (event.position-SIZE/2)/(0.014 if world_view else 1.1)
		coord = coord.clamp(Vector2.ONE*-12500,Vector2.ONE*12500)
		waypoint = Vector3(coord.x,CoastalRegion.height_at(coord.x,coord.y),coord.y)
		waypoint_selected.emit(waypoint)
		queue_redraw()
