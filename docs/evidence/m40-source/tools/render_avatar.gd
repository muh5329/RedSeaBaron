extends SceneTree
## Presentation-only captures of production player, worker and mounted rider.
func _initialize() -> void:
	capture.call_deferred()
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func save_view(path: String) -> void:
	await frames(2)
	RenderingServer.force_draw()
	root.get_texture().get_image().save_jpg("res://docs/evidence/"+path+".jpg")
func capture() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	game._set_paused(false)
	await frames(60)
	game._set_paused(true)
	game.hud.visible = false
	var camera := Camera3D.new()
	camera.fov = 48
	game.add_child(camera)
	camera.current = true
	camera.position = game.player.position+Vector3(2.5,1.85,-3.0)
	camera.look_at(game.player.position+Vector3(0,1.0,-0.1))
	await save_view("avatar-m39-front")
	camera.position = game.player.position+Vector3(-2.4,1.8,3.0)
	camera.look_at(game.player.position+Vector3.UP*1.0)
	await save_view("avatar-m39-back")
	var worker: WorkerActor = game.workers.workers[0]
	camera.position = worker.position+Vector3(2.5,1.85,-3.0)
	camera.look_at(worker.position+Vector3.UP*1.0)
	await save_view("avatar-m39-worker")
	game._set_paused(false)
	game.player.position = game.bike.position+Vector3(1.5,0.1,0)
	game.player.velocity = Vector3.ZERO
	await frames(60)
	var mounted: bool = game.seat.enter()
	print("RSB_AVATAR_RENDER | mounted=",mounted)
	game._set_paused(true)
	game.hud.visible = false
	camera.position = game.bike.position+Vector3(3.3,2.4,-3.7)
	camera.look_at(game.bike.position+Vector3(0,1.05,0))
	await save_view("avatar-m39-riding")
	quit()
