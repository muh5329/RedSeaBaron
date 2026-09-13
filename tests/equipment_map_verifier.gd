extends "res://tests/ui_verifier.gd"

func click_global(at: Vector2) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = get_viewport().get_final_transform()*at
		Input.parse_input_event(event)
		await frames(3)

func click_button(button: Button) -> void:
	await click_global(button.get_global_rect().get_center())

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var map: FieldMap = game.hud.map_drawing
	var cart: CargoCart = game.cart
	await frames(60)
	game.combat.equip("RIFLE")
	await key(KEY_M)
	bike.position = Vector3(-80,CoastalRegion.height_at(-80,55)+0.1,55)
	cart.position = Vector3(75,CoastalRegion.height_at(75,35)+0.1,35)
	var stock: Dictionary = cart.inventory.contents()
	var ammo: int = game.combat.ammunition
	await click_global(map.global_position+map.point(bike.position))
	check("Clicking motorcycle marker tracks its real location",map.tracked_asset==bike and game.hud.waypoint.distance_to(bike.position)<0.01 and map.waypoint_title=="Motorcycle")
	await frames(18)
	check("Tracked equipment appears in field notes",game.hud.objective.text.begins_with("Motorcycle"))
	check("Map selection preserves pause and weapon safety",game.paused and not bike.input_enabled and game.combat.ammunition==ammo)
	await click_button(game.hud.track_cart_button)
	check("Cargo button selects the detached cart",map.tracked_asset==cart and game.hud.waypoint.distance_to(cart.position)<0.01)
	cart.position = bike.position
	await click_button(game.hud.track_bike_button)
	var selected_bike := map.tracked_asset==bike
	await click_button(game.hud.track_cart_button)
	check("Overlapping map icons remain separately selectable",selected_bike and map.tracked_asset==cart)
	cart.position = Vector3(1400,CoastalRegion.height_at(1400,2300),2300)
	await click_button(game.hud.track_cart_button)
	check("Remote equipment automatically selects world scope",map.world_view and map.tracked_asset==cart and Rect2(Vector2.ZERO,map.SIZE).has_point(map.point(cart.position)))
	cart.position = Vector3(1600,CoastalRegion.height_at(1600,2500),2500)
	await frames(20)
	check("Tracked position refreshes without teleporting equipment",game.hud.waypoint.distance_to(cart.position)<0.01 and cart.inventory.contents()==stock)
	check("Unknown asset selection leaves current tracking intact",not map.track_asset("unknown") and map.tracked_asset==cart)
	await capture("equipment-world-map")
	# Keep this background-click fixture clear of the selectable dune marker at (6600,3000).
	var fixed := Vector3(7000,0,5000)
	await click_global(map.global_position+map.point(fixed))
	check("Ordinary map click replaces tracking with a fixed waypoint",map.tracked_asset==null and map.waypoint_title=="Waypoint" and Vector2(game.hud.waypoint.x-fixed.x,game.hud.waypoint.z-fixed.z).length()<2)
	await click_button(game.hud.clear_waypoint_button)
	check("Clear removes both map marker and field-note target",map.waypoint==null and game.hud.waypoint==null and map.tracked_asset==null)
	await click_button(game.hud.track_bike_button)
	await frames(18)
	check("Equipment controls fit the map viewport",game.hud.map_panel.get_global_rect().end.y<=get_viewport().get_visible_rect().size.y and game.hud.track_bike_button.get_global_rect().size.x>80)
	await capture("equipment-local-map")
	var saved: Dictionary = game.saves.snapshot()
	bike.position.x -= 30
	await frames(20)
	var followed_move: bool = game.hud.waypoint.distance_to(bike.position)<0.01
	var loaded: bool = await game.saves.restore(saved)
	await frames(20)
	check("Existing tracking follows equipment through save restore",loaded and followed_move and map.tracked_asset==bike and game.hud.waypoint.distance_to(bike.position)<0.01)
	await finish_report("equipment_map","32 parked equipment tracking",started,"--verify-equipment_map")
