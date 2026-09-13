extends SceneTree
## Optional real-scene presentation capture; does not substitute for gameplay checks.
func _initialize() -> void:
	capture.call_deferred()
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func capture() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	game._set_paused(false)
	game.world.enabled = false
	game.hud.visible = false
	game.player.position = Vector3(-20,CoastalRegion.height_at(-20,80)+0.1,80)
	game.player.velocity = Vector3.ZERO
	var camera := Camera3D.new()
	camera.fov = 50
	game.add_child(camera)
	camera.current = true
	for kind in ["Raider","Cinder beast"]:
		var enemy := EnemyActor.new()
		enemy.kind = kind
		enemy.target = game.player
		enemy.position = Vector3(-20,CoastalRegion.height_at(-20,78)+0.1,78)
		enemy.home = enemy.position
		game.add_child(enemy)
		enemy.brain.enabled = false
		await frames(30)
		enemy.face(game.player.position)
		camera.position = enemy.position+Vector3(3,2.7,4)
		camera.look_at(enemy.position+Vector3(0,0.9,0.4))
		await frames(5)
		RenderingServer.force_draw()
		root.get_texture().get_image().save_jpg("res://docs/evidence/m36-%s-detail.jpg"%kind.to_lower().replace(" ","-"))
		enemy.queue_free()
		await frames(2)
	quit()
