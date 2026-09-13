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
	await key(KEY_M)
	var map: FieldMap = game.hud.map_drawing
	map.world_view = true
	map.queue_redraw()
	await frames(20)
	var dunes := WorldLandforms.DUNES
	await click_map(map.point(Vector3(dunes.x,0,dunes.y))+Vector2(25,10))
	var gap: float = Vector2(game.hud.waypoint.x-dunes.x,game.hud.waypoint.z-dunes.y).length() if game.hud.waypoint!=null else INF
	check("Clicking the dunes label selects the exact named destination",game.hud.waypoint!=null and gap<1 and map.waypoint_title=="Saffron dunes","waypoint error=%.1f m title=%s"%[gap,map.waypoint_title])
	await finish_report("map_landmark","99 exact landform map destinations",started,"--verify-map_landmark")
