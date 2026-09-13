extends SceneTree
## Transaction/readability fixture; physical delivery journeys have separate verifiers.
func _initialize() -> void:
	capture.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func use_and_capture(game: Node3D, label: String) -> void:
	Input.action_press("use_resource")
	await frames(5)
	Input.action_release("use_resource")
	await frames(20)
	RenderingServer.force_draw()
	root.get_texture().get_image().save_jpg("res://docs/evidence/delivery-feedback-m54-"+label+".jpg")
	print("RSB_DELIVERY_FEEDBACK | ",label," | state=",game.logistics.contract.state," | credits=",game.logistics.shop.credits," | text=",game.hud.notification.text)
func capture() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.verification_session = true
	await frames(5)
	game._begin()
	game.player.position = game.logistics.dispatch.position+Vector3(0,0.1,2.5)
	game.player.velocity = Vector3.ZERO
	await frames(30)
	Input.action_press("use_resource")
	await frames(5)
	Input.action_release("use_resource")
	game.player.position = game.logistics.destination.position+Vector3(0,0.1,2.5)
	game.player.velocity = Vector3.ZERO
	game.orbit.yaw = 0
	game.orbit.snap()
	await frames(30)
	await use_and_capture(game,"paid")
	await use_and_capture(game,"repeat")
	quit()
