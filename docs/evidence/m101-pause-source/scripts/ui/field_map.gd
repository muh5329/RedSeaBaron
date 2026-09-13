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
const REGION_LABEL_OFFSETS := {"greenreach":Vector2(-107,22),"red_mesa":Vector2(12,5),"snowwatch":Vector2(-36,-12),"longfield":Vector2(12,28)}

func _ready() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true

func point(at: Vector3) -> Vector2:
	return SIZE/2+Vector2(at.x,at.z)*(0.014 if world_view else 1.1)

func mark(at: Vector3, caption: String, color: Color, radius: float = 5) -> void:
	var p := point(at)
	draw_circle(p,radius,color)
	_caption(p+Vector2(9,4),caption,13)

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
	draw_texture_rect(TerrainCartography.texture(Vector2.ZERO,SIZE/(0.014 if world_view else 1.1),Vector2i(255,195)),Rect2(Vector2.ZERO,SIZE),false)
	if world_view:
		for x in range(80,431,70): draw_line(Vector2(x,20),Vector2(x,370),Color("91a28e"),1)
		for y in range(20,371,70): draw_line(Vector2(80,y),Vector2(430,y),Color("91a28e"),1)
		mark(Vector3.ZERO,"Port Solis",Color("315e59"),6)
		var brook := point(Vector3(RegionalBrook.CENTER.x,0,RegionalBrook.CENTER.y))
		draw_line(brook+Vector2(0,-3),brook+Vector2(0,3),Color("438a9a"),2)
		draw_line(brook,brook+Vector2(-50,-18),Color("438a9a"),1)
		_caption(brook+Vector2(-105,-22),"Solis brook",12)
		var lake := point(Vector3(RegionalLake.CENTER.x,RegionalLake.LEVEL,RegionalLake.CENTER.y))
		draw_circle(lake,3,Color("438a9a"))
		draw_line(lake,lake+Vector2(-22,-10),Color("438a9a"),1)
		_caption(lake+Vector2(-100,-14),"Willowmere",12)
		for region in RegionCatalog.all():
			var p := point(region.position_3d())
			draw_circle(p,4,Color("f7e5b8") if regions and regions.discovered.get(region.id,false) else region.accent)
			if not region.hostile_kinds.is_empty(): draw_arc(p,7,0,TAU,16,Color("a34d3e"),2)
			_caption(p+REGION_LABEL_OFFSETS[region.id],region.title.split(" ")[0],12)
		_caption(Vector2(90,45),"HIGHLANDS",13)
		_caption(Vector2(88,350),"25 km × 25 km",13)
	else:
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
	for feature: Dictionary in landmark_layout():
		if feature.kind=="Region": continue
		var at := point(feature.coordinate)
		draw_circle(at,3,Color("f4d49c"))
		if feature.kind=="Cave": draw_line(at,feature.label-Vector2(0,3),Color("394f47"),1)
		_caption(feature.label,feature.text,feature.font_size)
	if world_view:
		_caption(Vector2(91,331),"FOREST              GRASSLAND              DESERT",10)
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
			_caption(at+Vector2(8,-7 if i%2==0 else 15),worker.worker_name,11)
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
		var entries := landmark_layout()
		for entry: Dictionary in entries:
			if entry.rect.has_point(event.position):
				select_landmark(entry)
				return
		var nearest: Dictionary = {}
		var landmark_distance := 7.0
		for entry: Dictionary in entries:
			var distance := point(entry.coordinate).distance_to(event.position)
			if distance<landmark_distance:
				nearest = entry
				landmark_distance = distance
		if not nearest.is_empty():
			select_landmark(nearest)
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

func _caption(at: Vector2, text: String, font_size: int = 12) -> void:
	draw_string_outline(ThemeDB.fallback_font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,3,Color("243e38"))
	draw_string(ThemeDB.fallback_font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("f4e9cb"))

func landmark_layout() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for feature in WorldLandforms.landmarks():
		if (world_view and feature[2]=="Beach") or (not world_view and feature[2]!="Beach"): continue
		var coordinate: Vector2 = feature[1]
		var position := Vector3(coordinate.x,CoastalRegion.height_at(coordinate.x,coordinate.y),coordinate.y)
		var label_at := point(position)+Vector2(8,14)
		var text: String = feature[0]
		var font_size := 10
		if feature[2]=="Cave":
			label_at = point(position)+Vector2(26,-26)
			text = "△ Quarry cave"
			font_size = 11
		elif feature[2]=="Beach":
			label_at = point(position)+Vector2(9,4)
			text = "Beach"
			font_size = 13
		result.append(_landmark_entry(position,feature[0],feature[2],label_at,text,font_size))
	if world_view:
		for region in RegionCatalog.all():
			var position := region.position_3d()
			result.append(_landmark_entry(position,region.title,"Region",point(position)+REGION_LABEL_OFFSETS[region.id],region.title.split(" ")[0],12))
	return result

func _landmark_entry(coordinate: Vector3, title: String, kind: String, label_at: Vector2, text: String, font_size: int) -> Dictionary:
	var measured := ThemeDB.fallback_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
	return {"coordinate":coordinate,"title":title,"kind":kind,"label":label_at,"text":text,"font_size":font_size,"rect":Rect2(label_at-Vector2(0,font_size),measured+Vector2(0,4))}

func select_landmark(entry: Dictionary) -> void:
	tracked_asset = null
	tracking_active = false
	tracking_checkpoint = false
	waypoint = entry.coordinate
	waypoint_title = entry.title
	waypoint_selected.emit(waypoint)
	queue_redraw()
