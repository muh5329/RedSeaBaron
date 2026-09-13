extends "res://tests/equipment_map_verifier.gd"

func follows(point: Vector3) -> bool:
	return game.hud.waypoint!=null and game.hud.waypoint.distance_to(point)<0.01

func survey(at: Vector2) -> void:
	player.position = Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+0.2,at.y)
	player.velocity = Vector3.ZERO
	await frames(90)
	await key(KEY_E)
	await frames(20)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var map: FieldMap = game.hud.map_drawing
	game.encounters.set_enabled(false)
	await frames(60)
	game.combat.equip("RIFLE")
	var ammo: int = game.combat.ammunition
	await key(KEY_M)
	var button: Button
	for candidate in game.hud.map_panel.find_children("*","Button",true,false):
		if candidate.text=="Checkpoint": button = candidate
	check("Map offers an explicit recovery checkpoint target",button!=null)
	if button==null:
		await finish_report("checkpoint_map","81 recovery checkpoint guidance",started,"--verify-checkpoint_map")
		return
	await click_button(button)
	await frames(20)
	check("Button selects the current checkpoint independently of player tracking",map.tracking_checkpoint and map.tracked_asset==null and follows(player.spawn_position) and map.waypoint_title=="Recovery checkpoint")
	check("Checkpoint selection preserves pause and rifle ammunition",game.paused and not player.input_enabled and game.combat.ammunition==ammo)
	await capture("checkpoint-m81-local")
	await key(KEY_M)
	await survey(Vector2(888,1109.5))
	var regional := player.spawn_position
	check("An actual regional survey updates guidance and world scope",regional.x>800 and map.world_view and follows(regional),"checkpoint=%s"%regional)
	await key(KEY_M)
	await frames(20)
	check("Regional checkpoint has readable field notes and map location",game.hud.objective.text.begins_with("Recovery checkpoint") and Rect2(Vector2.ZERO,map.SIZE).has_point(map.point(regional)))
	await capture("checkpoint-m81-world")
	var saved: Dictionary = game.saves.snapshot()
	await key(KEY_M)
	await survey(Vector2(0,-0.5))
	check("Returning to a village survey updates the tracked checkpoint",player.spawn_position.x<1 and not map.world_view and follows(player.spawn_position) and player.spawn_position.distance_to(regional)>1000)
	await key(KEY_M)
	var restored: bool = await game.saves.restore(saved)
	game.encounters.set_enabled(false)
	await frames(20)
	check("Save restore updates checkpoint guidance without stale coordinates",restored and follows(regional) and map.tracking_checkpoint and map.world_view and game.paused and game.hud.map_panel.visible and not game.hud.menu.visible)
	await click_button(game.hud.track_bike_button)
	check("Equipment selection releases checkpoint tracking",not map.tracking_checkpoint and map.tracked_asset==bike and follows(bike.position))
	await click_button(button)
	await click_button(game.hud.track_worker_buttons["ivo"])
	check("Worker selection releases checkpoint tracking",not map.tracking_checkpoint and map.tracked_asset==game.workers.worker_by_id("ivo"))
	await click_button(button)
	# Background fixture stays clear of the new selectable dune marker.
	var fixed := Vector3(7000,0,5000)
	await click_global(map.global_position+map.point(fixed))
	check("A fixed map point replaces checkpoint tracking",not map.tracking_checkpoint and not map.tracking_active and map.waypoint_title=="Waypoint" and Vector2(game.hud.waypoint.x-fixed.x,game.hud.waypoint.z-fixed.z).length()<2)
	await click_button(button)
	await click_button(game.hud.clear_waypoint_button)
	await key(KEY_M)
	await survey(Vector2(0,-0.5))
	check("Cleared checkpoint guidance stays clear after another survey",not map.tracking_checkpoint and not map.tracking_active and map.waypoint==null and game.hud.waypoint==null)
	await key(KEY_M)
	await frames(20)
	var viewport := get_viewport().get_visible_rect()
	var panel: Rect2 = game.hud.map_panel.get_global_rect()
	check("Checkpoint controls fit without another map row",viewport.encloses(panel) and button.size.x>80 and panel.encloses(button.get_global_rect()))
	await capture("checkpoint-m81-final-map")
	await finish_report("checkpoint_map","81 recovery checkpoint guidance",started,"--verify-checkpoint_map")
