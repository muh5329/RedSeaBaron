extends SceneTree

func _initialize() -> void:
	render.call_deferred()

func render() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.verification_session = true
	game._begin()
	var center := Vector3(-3600,0,700)
	center.y = CoastalRegion.height_at(center.x,center.z)
	game.player.position = center+Vector3(20,6,58)
	game.player.velocity = Vector3.ZERO
	for i in range(140): await physics_frame
	game._set_paused(true)
	game.hud.root.visible = false
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.position = center+Vector3(42,15,83)
	camera.look_at(center+Vector3(10,5,20))
	camera.current = true
	for i in range(2): await physics_frame
	RenderingServer.force_draw()
	var tag := "current"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="): tag = arg.trim_prefix("--label=")
	root.get_texture().get_image().save_jpg("res://docs/evidence/forest-form-%s.jpg"%tag)
	print("TREE_RENDER_ONLY | calls=%d resident=%d mesh_vertices=%d"%[Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),game.world.streamer.chunks.size(),RegionScenery.model("tree").surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()])
	quit()
