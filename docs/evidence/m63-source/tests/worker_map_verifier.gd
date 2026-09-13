extends "res://tests/equipment_map_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var map: FieldMap = game.hud.map_drawing
	var manager: WorkerManager = game.workers
	var mara := manager.worker_by_id("mara")
	var ivo := manager.worker_by_id("ivo")
	await frames(120)
	game.combat.equip("RIFLE")
	var ammo: int = game.combat.ammunition
	await key(KEY_M)
	mara.position = Vector3(-100,CoastalRegion.height_at(-100,30)+0.1,30)
	ivo.position = Vector3(-30,CoastalRegion.height_at(-30,35)+0.1,35)
	mara.velocity = Vector3.ZERO
	ivo.velocity = Vector3.ZERO
	await click_global(map.global_position+map.point(mara.position))
	check("Worker marker selects Mara's real position",map.tracked_asset==mara and map.tracking_active and game.hud.waypoint.distance_to(mara.position)<0.01)
	await frames(20)
	check("Tracked worker appears in field notes",game.hud.objective.text.begins_with("Mara"))
	check("Worker map selection preserves pause and ammunition",game.paused and not ivo.enabled and game.combat.ammunition==ammo)
	await click_button(game.hud.track_worker_buttons["ivo"])
	check("Worker button selects Ivo independently",map.tracked_asset==ivo and map.waypoint_title=="Ivo")
	var before := ivo.position
	ivo.position = mara.position
	await click_button(game.hud.track_worker_buttons["mara"])
	var selected_mara := map.tracked_asset==mara
	await click_button(game.hud.track_worker_buttons["ivo"])
	check("Overlapping workers remain individually selectable",selected_mara and map.tracked_asset==ivo)
	ivo.position = before
	await frames(20)
	await capture("worker-m61-local-map")
	await key(KEY_M)
	manager.selected_worker_index = manager.workers.find(ivo)
	var assigned := manager.order("Transport")
	await frames(180)
	await key(KEY_M)
	await frames(20)
	check("Tracking follows real worker job movement",assigned and ivo.position.distance_to(before)>5 and map.tracked_asset==ivo and game.hud.waypoint.distance_to(ivo.position)<0.01,"moved=%.2f state=%s"%[ivo.position.distance_to(before),ivo.machine.current])
	var saved: Dictionary = game.saves.snapshot()
	ivo.position.x -= 30
	await frames(20)
	var followed: bool = game.hud.waypoint.distance_to(ivo.position)<0.01
	var restored: bool = await game.saves.restore(saved)
	await frames(20)
	check("Tracking follows the same worker through save restoration",restored and followed and map.tracked_asset==ivo and game.hud.waypoint.distance_to(ivo.position)<0.01 and ivo.executor.job.kind=="Transport")
	check("Save restoration preserves the map without a second menu",game.paused and game.hud.map_panel.visible and not game.hud.menu.visible)
	check("Unknown worker ID leaves tracking intact",not map.track_worker("missing") and map.tracked_asset==ivo)
	var saved_position := ivo.position
	ivo.position = Vector3(-3600,CoastalRegion.height_at(-3600,716),716)
	await click_button(game.hud.track_worker_buttons["ivo"])
	check("Remote worker switches to a usable world scope",map.world_view and Rect2(Vector2.ZERO,map.SIZE).has_point(map.point(ivo.position)) and game.hud.waypoint.distance_to(ivo.position)<0.01)
	await frames(20)
	await capture("worker-m61-world-map")
	ivo.position = saved_position
	var temporary := WorkerActor.new()
	temporary.worker_id = "temporary"
	temporary.worker_name = "Temporary"
	temporary.navigation = manager.navigation
	temporary.home = game.logistics.warehouse
	manager.add_child(temporary)
	manager.workers.append(temporary)
	map.track_worker("temporary")
	manager.workers.erase(temporary)
	temporary.queue_free()
	await frames(20)
	check("Retiring a tracked worker clears stale guidance safely",not map.tracking_active and map.tracked_asset==null and map.waypoint==null and game.hud.waypoint==null)
	await click_button(game.hud.track_worker_buttons["mara"])
	var fixed := Vector3(90,0,-70)
	await click_global(map.global_position+map.point(fixed))
	check("Fixed waypoint replaces worker tracking",not map.tracking_active and map.tracked_asset==null and map.waypoint_title=="Waypoint" and Vector2(game.hud.waypoint.x-fixed.x,game.hud.waypoint.z-fixed.z).length()<2)
	await click_button(game.hud.track_worker_buttons["ivo"])
	await click_button(game.hud.clear_waypoint_button)
	check("Clear removes worker and HUD waypoint",map.waypoint==null and map.tracked_asset==null and game.hud.waypoint==null)
	check("Worker map controls fit the viewport",game.hud.map_panel.get_global_rect().end.y<=get_viewport().get_visible_rect().size.y and game.hud.track_worker_buttons["mara"].size.x>80 and game.hud.track_worker_buttons["ivo"].size.x>80)
	await key(KEY_M)
	await key(KEY_N)
	await frames(20)
	await capture("worker-m61-orders")
	await finish_report("worker_map","61 worker map tracking",started,"--verify-worker_map")
