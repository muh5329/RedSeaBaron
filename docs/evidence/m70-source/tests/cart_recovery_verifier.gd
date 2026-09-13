extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await frames(60)
	var cart: CargoCart = game.cart
	var home := cart.position
	# Isolate bounds recovery from water and distance-based suspension.
	game.world.enabled = false
	game.water.enabled = false
	cart.enabled = true
	cart.inventory.add("ore",20)
	cart.position = Vector3(500,-65,500)
	cart.velocity = Vector3(5,-15,0)
	await frames(10)
	check("A fallen detached cart returns to its workshop",cart.position.distance_to(home)<2,"cart=%s home=%s"%[cart.position,home])
	cart.enabled = true
	cart.position = Vector3(WorldStreamer.HALF_EXTENT+2,20,0)
	cart.velocity = Vector3(8,0,0)
	await frames(10)
	check("A detached cart beyond the world domain returns safely",cart.position.distance_to(home)<2,"cart=%s"%cart.position)
	check("Recovery conserves the original detached cargo actor and goods",game.cart==cart and cart.inventory.count("ore")==20 and cart.tow_vehicle==null)
	check("Recovery clears residual motion and orientation",cart.velocity==Vector3.ZERO and cart.rotation==Vector3.ZERO)
	for edge in [Vector3(-WorldStreamer.HALF_EXTENT-2,20,0),Vector3(0,20,WorldStreamer.HALF_EXTENT+2),Vector3(0,20,-WorldStreamer.HALF_EXTENT-2)]:
		cart.position = edge
		cart.enabled = true
		await frames(2)
		check("Domain recovery covers edge %s"%edge,cart.position.distance_to(home)<2)
	cart.position = Vector3(200,-10,0)
	cart.enabled = true
	await frames(3)
	check("Legitimate seabed depth is not treated as a world fall",cart.position.x>190 and cart.position.y>-12)
	cart.position = Vector3(500,-65,500)
	game._set_paused(true)
	await frames(3)
	check("Paused cargo cannot recover or move",cart.position==Vector3(500,-65,500))
	game._set_paused(false)
	cart.enabled = true
	await frames(3)
	check("Resumed invalid cargo recovers",cart.position.distance_to(home)<2)
	game.world.enabled = true
	player.position = Vector3(0,CoastalRegion.height_at(0,950)+1,950)
	player.velocity = Vector3.ZERO
	cart.position = Vector3(0,-65,950)
	game.world.refresh_tiers()
	await frames(5)
	check("Distant recovery suspends home cargo without activating the core",not game.world.core_active and not cart.enabled and not cart.visible and cart.position.distance_to(home)<2)
	var parked := cart.position
	await frames(30)
	check("Recovered distant cargo cannot fall through suspended home terrain",cart.position==parked and cart.inventory.count("ore")==20)
	player.recover()
	await frames(60)
	check("Returning to town restores solid ground beneath recovered cargo",game.world.core_active and cart.is_on_floor() and cart.visible)
	await place()
	cart.position = bike.position+bike.global_basis.z*3.3+Vector3.UP*0.15
	cart.velocity = Vector3.ZERO
	cart.rotation = bike.rotation
	await frames(30)
	check("Coupled recovery fixture mounts and hitches normally",seat.enter() and game.hitch.toggle())
	cart.position = Vector3(500,-65,500)
	cart.enabled = true
	await frames(5)
	check("Invalid attached cargo recovers the complete coupled vehicle",bike.position.distance_to(bike.home)<2 and cart.position.distance_to(bike.position)<4.5 and seat.mounted and cart.tow_vehicle==bike and bike.cart_attached)
	await frames(30)
	check("Coupled recovery preserves load and returns both bodies to solid ground",cart.inventory.count("ore")==20 and bike.cargo_mass==100 and bike.is_on_floor() and cart.is_on_floor())
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		game.orbit.yaw = -0.55
		game.orbit.pitch = -0.3
		game.orbit.distance = 8
		game.orbit.snap()
		await frames(20)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/cart-recovery-m69.jpg")
	await finish_report("cart_recovery","69 detached cargo recovery",started,"--verify-cart_recovery")
