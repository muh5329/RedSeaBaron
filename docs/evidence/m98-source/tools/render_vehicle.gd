extends SceneTree
## Optional presentation captures from the real main scene; no gameplay acceptance assertions.
func _initialize() -> void:
	capture.call_deferred()

func frame_count(n: int) -> void:
	for i in range(n): await physics_frame

func capture() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frame_count(5)
	game._set_paused(false)
	await frame_count(90)
	for node in game.bike.visual.get_children():
		if node.name=="FuelTank": print("RSB_TANK | aabb=",node.mesh.get_aabb()," position=",node.position," surfaces=",node.mesh.get_surface_count())
	game.hud.visible = false
	game.player.visible = false
	var camera := Camera3D.new()
	camera.fov = 45
	game.add_child(camera)
	camera.current = true
	camera.position = game.bike.position+Vector3(-3,1.9,-3.4)
	camera.look_at(game.bike.position+Vector3(0,0.85,0))
	await frame_count(15)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg("res://docs/evidence/motorcycle-native-detail.jpg")
	print("RSB_VEHICLE_RENDER | motorcycle draw_calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	camera.position = game.cart.position+Vector3(-3,2.3,3.5)
	camera.look_at(game.cart.position+Vector3(0,0.9,0))
	await frame_count(15)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg("res://docs/evidence/cart-native-detail-empty.jpg")
	var before: int = game.cart.find_children("*","",true,false).size()
	for i in range(100):
		game.cart.inventory.add("ore",20)
		game.cart.inventory.remove("ore",20)
	game.cart.inventory.add("ore",20)
	await frame_count(15)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg("res://docs/evidence/cart-native-detail-loaded.jpg")
	print("RSB_CART_RENDER | before_nodes=",before," loaded_nodes=",game.cart.find_children("*","",true,false).size()," cargo_mass=",game.cart.inventory.mass()," draw_calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	game.bike.transformation.request_toggle()
	await frame_count(85)
	camera.position = game.bike.position+Vector3(-7,4.5,-8)
	camera.look_at(game.bike.position+Vector3(0,1.1,0.5))
	await frame_count(15)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg("res://docs/evidence/motorcycle-native-aircraft.jpg")
	print("RSB_VEHICLE_RENDER | mode=",game.bike.transformation.mode," draw_calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	quit()
