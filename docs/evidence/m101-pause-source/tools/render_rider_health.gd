extends SceneTree
## Presentation review using production damage and mounted-death recovery.
func _initialize() -> void:
	capture.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func save_view(label: String) -> void:
	await frames(20)
	RenderingServer.force_draw()
	root.get_texture().get_image().save_jpg("res://docs/evidence/rider-health-m50-"+label+".jpg")
func capture() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.verification_session = true
	await frames(5)
	game._set_paused(false)
	game.player.position = game.bike.position+Vector3(1.5,0.1,0)
	game.player.velocity = Vector3.ZERO
	await frames(60)
	var mounted: bool = game.seat.enter()
	var damaged: bool = game.combat.health.take_damage(35,&"hostile")
	await save_view("damaged")
	print("RSB_RIDER_HEALTH_CAPTURE | mounted=",mounted," damage accepted=",damaged," health=",game.combat.health.current," readout=",game.hud.health_label.text)
	game.combat.health.take_damage(999,&"hostile")
	await frames(140)
	await save_view("recovered")
	print("RSB_RIDER_HEALTH_CAPTURE | mounted=",game.seat.mounted," actor visible=",game.player.visible," health=",game.combat.health.current," readout=",game.hud.health_label.text)
	quit()
