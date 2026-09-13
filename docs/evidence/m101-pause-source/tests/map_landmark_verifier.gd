extends "res://tests/ui_verifier.gd"

func click_map(at: Vector2) -> void:
	var map: FieldMap = game.hud.map_drawing
	for held in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = held
		event.position = get_viewport().get_final_transform()*(map.global_position+at)
		Input.parse_input_event(event)
		await frames(3)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await frames(40)
	game.combat.equip("RIFLE")
	var ammo: int = game.combat.ammunition
	await key(KEY_M)
	var map: FieldMap = game.hud.map_drawing
	map.world_view = true
	map.queue_redraw()
	await frames(20)
	var dunes := WorldLandforms.DUNES
	await click_map(map.point(Vector3(dunes.x,0,dunes.y))+Vector2(25,10))
	var gap: float = Vector2(game.hud.waypoint.x-dunes.x,game.hud.waypoint.z-dunes.y).length() if game.hud.waypoint!=null else INF
	check("Clicking the dunes label selects the exact named destination",game.hud.waypoint!=null and gap<1 and map.waypoint_title=="Saffron dunes","waypoint error=%.1f m title=%s"%[gap,map.waypoint_title])
	for spec in [
		["Windcut valley",Vector2(-800,-6500),Vector2(25,10)],
		["Crown mountains",Vector2(-1800,-8600),Vector2(25,10)],
		["Whitecap peak",Vector2(1100,-10300),Vector2(25,10)],
		["Quarry cave",QuarryAdit.CENTER,Vector2(45,-30)],
		["Greenreach timber camp",Vector2(-3600,700),Vector2(-87,18)],
		["Red Mesa quarry",Vector2(4800,1200),Vector2(32,1)],
		["Snowwatch tower",Vector2(-1060,-10000),Vector2(-16,-16)],
		["Longfield waystation",Vector2(900,1100),Vector2(32,24)]
	]:
		var at: Vector2 = spec[1]
		await click_map(map.point(Vector3(at.x,0,at.y))+spec[2])
		gap = Vector2(game.hud.waypoint.x-at.x,game.hud.waypoint.z-at.y).length() if game.hud.waypoint!=null else INF
		check("Named map label selects "+spec[0],gap<1 and map.waypoint_title==spec[0],"error=%.1f title=%s"%[gap,map.waypoint_title])
	await click_map(Vector2(300,320))
	var expected := (Vector2(300,320)-FieldMap.SIZE/2)/0.014
	gap = Vector2(map.waypoint.x,map.waypoint.z).distance_to(expected)
	check("Unmarked map space still sets an exact cursor waypoint",gap<1 and map.waypoint_title=="Waypoint")
	map.track_asset("bike")
	map.world_view = true
	map.queue_redraw()
	await frames(20)
	await click_map(map.point(Vector3(dunes.x,0,dunes.y))+Vector2(25,10))
	check("Choosing a place cancels prior live asset tracking",not map.tracking_active and map.tracked_asset==null and map.waypoint_title=="Saffron dunes")
	map.world_view = false
	map.queue_redraw()
	await frames(20)
	await click_map(map.point(Vector3(85,0,60))+Vector2(25,0))
	check("Local beach label selects the named shoreline",map.waypoint_title=="Solis beach" and Vector2(map.waypoint.x-85,map.waypoint.z-60).length()<1)
	check("Beach destination lies on dry ground",WaterBody.new().depth_at(map.waypoint)==0)
	map.world_view = true
	map.queue_redraw()
	await frames(20)
	await click_map(map.point(Vector3(dunes.x,0,dunes.y)))
	check("Landform marker also selects its exact destination",map.waypoint_title=="Saffron dunes" and Vector2(map.waypoint.x-dunes.x,map.waypoint.z-dunes.y).length()<1)
	check("Named map clicks preserve pause and ammunition",game.paused and game.hud.map_panel.visible and game.combat.ammunition==ammo)
	await frames(20)
	await capture("landmark-destination-m99")
	for held in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = held
		event.position = get_viewport().get_final_transform()*game.hud.clear_waypoint_button.get_global_rect().get_center()
		Input.parse_input_event(event)
		await frames(3)
	check("Clear button removes a named waypoint",map.waypoint==null and game.hud.waypoint==null and not map.tracking_active)
	await key(KEY_M)
	check("Closing destination selection restores gameplay and minimap",not game.paused and game.hud.minimap.visible)
	await finish_report("map_landmark","99 exact landform map destinations",started,"--verify-map_landmark")
