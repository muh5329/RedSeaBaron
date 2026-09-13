extends "res://tests/worker_verifier.gd"

func coastal_surface() -> MeshInstance3D:
	for child in game.region.get_children():
		if child is MeshInstance3D and child.mesh is PlaneMesh and absf(child.position.y-game.region.sea.level)<0.01: return child
	return null

func sample_water(camera: Camera3D, at: Vector3, offset: Vector3, name: String) -> Color:
	camera.position = at+offset
	camera.look_at(at+(Vector3.ZERO if name=="a" else Vector3(8,0,0)))
	await frames(3)
	RenderingServer.force_draw()
	var picture := get_viewport().get_texture().get_image()
	var projected := camera.unproject_position(at)
	var pixel := Vector2i(projected*Vector2(picture.get_size())/get_viewport().get_visible_rect().size)
	print("WATER_CAMERA_SAMPLE ",name," projected=",projected," viewport=",get_viewport().get_visible_rect().size," image=",picture.get_size()," pixel=",pixel)
	var color := Color(0,0,0,0)
	for x in range(-1,2):
		for y in range(-1,2): color += picture.get_pixelv(pixel+Vector2i(x,y))
	if "--capture" in OS.get_cmdline_user_args(): picture.save_jpg("res://docs/evidence/water-camera-m68-%s.jpg"%name)
	return color/9.0

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await frames(60)
	var water := coastal_surface()
	check("Coastal water render occupies its safety resource's level",water!=null and is_equal_approx(water.global_position.y,game.region.sea.level) and water.mesh.size==game.region.sea.bounds.size)
	var point := Vector3(200,game.region.sea.level,0)
	check("The visual sample lies over genuinely submerged terrain",CoastalRegion.height_at(point.x,point.z)<point.y-1 and absf(game.water.depth_at(point-Vector3.UP)-1)<0.01)
	if DisplayServer.get_name()!="headless" and water!=null:
		var original: ShaderMaterial = water.material_override
		var material: ShaderMaterial = original.duplicate()
		var shader := Shader.new()
		# Freeze only animation time, leaving the production coordinate expression intact.
		shader.code = original.shader.code.replace("TIME","probe_time").replace("shader_type spatial;","shader_type spatial; uniform float probe_time = 1.3;")
		material.shader = shader
		var was_processing := water.is_processing()
		water.set_process(false)
		water.material_override = material
		if shader.code.contains("wave_time"): material.set_shader_parameter("wave_time",1.3)
		game.orbit.set_physics_process(false)
		game.hud.root.visible = false
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.current = true
		var a := await sample_water(camera,point,Vector3(18,12,0),"a")
		var b := await sample_water(camera,point,Vector3(0,12,18),"b")
		var difference := Vector3(a.r-b.r,a.g-b.g,a.b-b.b).length()
		check("Camera motion cannot drag the ripple pattern over a fixed world point",difference<0.025,"color a=%s b=%s difference=%.5f"%[a,b,difference])
		material.set_shader_parameter("wave_time",12.0)
		var animated := await sample_water(camera,point,Vector3(0,12,18),"animated")
		var animation_delta := Vector3(animated.r-b.r,animated.g-b.g,animated.b-b.b).length()
		check("World anchoring retains animated water variation",animation_delta>0.008,"phase difference=%.5f"%animation_delta)
		water.material_override = original
		water.set_process(was_processing)
		camera.queue_free()
		game.orbit.camera.current = true
		game.orbit.set_physics_process(true)
		game.hud.root.visible = true
	await finish_report("water_camera","68 world-anchored water rendering",started,"--verify-water_camera")
