class_name TravelMinimap
extends Control
var player: PlayerController
var seat: VehicleSeat
var map: FieldMap
var center := Vector2(INF,INF)
var terrain: Texture2D
var rebuilds: int = 0
var clock: float = 0
const METERS: float = 640
const RADIUS: float = 90
const MID := Vector2(108,103)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(216,208)

func _process(delta: float) -> void:
	if not visible or not is_instance_valid(player): return
	clock += delta
	if clock<0.1: return
	clock = 0
	var snapped := (Vector2(player.position.x,player.position.z)/128).round()*128
	if snapped!=center:
		center = snapped
		terrain = TerrainCartography.texture(center,Vector2.ONE*METERS,Vector2i(64,64))
		rebuilds += 1
	queue_redraw()

func project(at: Vector3) -> Vector2:
	return MID+Vector2(at.x-player.position.x,at.z-player.position.z)*0.4

func marker(at: Vector3, color: Color, radius: float = 3) -> void:
	var p := project(at)
	if Rect2(14,22,188,164).has_point(p): draw_circle(p,radius,color)

func _draw() -> void:
	draw_style_box(panel_style(),Rect2(Vector2.ZERO,Vector2(216,208)))
	if terrain and player:
		var offset := (center-Vector2(player.position.x,player.position.z))*0.4
		draw_texture_rect_region(terrain,Rect2(14,22,188,164),Rect2((Vector2(14,22)-MID-offset+Vector2.ONE*128)/4,Vector2(188,164)/4))
		for z in range(-140,98,4):
			road(Vector3(4+sin(z*0.018)*10,0,z),Vector3(4+sin((z+4)*0.018)*10,0,z+4))
		for i in range(30):
			road(Vector3(-i*1.8,0,-34-i*0.8),Vector3(-(i+1)*1.8,0,-34-(i+1)*0.8))
		for region in RegionCatalog.all(): marker(region.position_3d(),Color("f5d68a"),4)
		for feature in WorldLandforms.landmarks(): marker(Vector3(feature[1].x,0,feature[1].y),Color("edf0e1"),3)
		if map:
			if is_instance_valid(map.cart): marker(map.cart.position,Color("e6bd72"),4)
			if is_instance_valid(map.bike): marker(map.bike.position,Color("bc5b45"),4)
			if map.waypoint!=null:
				var target := project(map.waypoint).clamp(Vector2(19,28),Vector2(197,181))
				draw_arc(target,6,0,TAU,16,Color("ffe2a4"),2,true)
		marker(player.spawn_position,Color("c4e6df"),4)
		var yaw := seat.bike.rotation.y if seat and seat.mounted else player.visual.global_rotation.y
		var arrow := PackedVector2Array()
		for v in [Vector2(0,-8),Vector2(5,6),Vector2(0,3),Vector2(-5,6)]: arrow.append(MID+v.rotated(-yaw))
		draw_colored_polygon(arrow,Color("fff7d9"))
	draw_string(ThemeDB.fallback_font,Vector2(16,16),"N ↑     FIELD COMPASS",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e9dfc6"))
	draw_line(Vector2(16,196),Vector2(56,196),Color("e9dfc6"),2)
	draw_string(ThemeDB.fallback_font,Vector2(64,199),"100 m       M  Map",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e9dfc6"))

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("213d39")
	style.set_corner_radius_all(8)
	return style

func road(a: Vector3, b: Vector3) -> void:
	var first := project(a)
	var second := project(b)
	var bounds := Rect2(14,22,188,164)
	if bounds.has_point(first) and bounds.has_point(second): draw_line(first,second,Color("ead2a1"),2,true)
