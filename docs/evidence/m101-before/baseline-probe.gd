extends SceneTree
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func _initialize() -> void: run_probe.call_deferred()
func run_probe() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.verification_session = true
	game._begin()
	await frames(80)
	game.world.enabled = false
	game.bike.set_physics_process(false)
	game.bike.position = Vector3(-100,CoastalRegion.height_at(-100,80)+0.1,80)
	var nav := NavigationController.new()
	game.add_child(nav)
	var intermediate := Vector3(0,CoastalRegion.height_at(0,80)+0.1,80)
	var cell := nav.coordinate(intermediate)
	var index := cell.y*nav.side_cells+cell.x
	while nav.cursor<index-192: await frames(1)
	game.bike.position = intermediate
	while nav.cursor<=index: await frames(1)
	var was_blocked := nav.grid.is_point_solid(cell)
	game.bike.position = Vector3(100,CoastalRegion.height_at(100,80)+0.1,80)
	await frames(45)
	var stale := nav.grid.is_point_solid(cell)
	var report := {"sampled_intermediate_body":was_blocked,"stale_intermediate_cell":stale,"ready":nav.ready_for_paths,"passed":was_blocked and not stale}
	print("RSB_STARTUP_HISTORY_PROBE ",JSON.stringify(report))
	var out := FileAccess.open("/tmp/rsb_startup_history_report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(report,"  "))
	out.close()
	game.audio.enabled = false
	game.queue_free()
	await process_frame
	await process_frame
	quit()
