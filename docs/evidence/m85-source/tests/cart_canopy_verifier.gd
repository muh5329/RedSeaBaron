extends "res://tests/worker_verifier.gd"
var cart: CargoCart

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	cart = game.cart
	var started := Time.get_ticks_msec()
	await place(Vector2(0,110))
	game.world.enabled = false
	var platform := BlockoutKit.box(game,Vector3(0,29.5,110),Vector3(80,1,120),Color("937957"),true)
	bike.position = Vector3(0,30.2,110)
	bike.velocity = Vector3.ZERO
	cart.position = bike.position+Vector3(0,0.1,3.3)
	cart.rotation = Vector3.ZERO
	cart.velocity = Vector3.ZERO
	player.position = bike.position+Vector3(1.65,0.1,0)
	player.velocity = Vector3.ZERO
	await frames(60)
	cart.inventory.add("ore",40)
	for x in [0.0,-0.6,0.6]:
		var top := cart.visual.global_transform*Vector3(x,1.78+0.60*sqrt(1-pow(x/0.86,2)),0)
		var hit := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(top+Vector3.UP,top-Vector3.UP*2,16))
		check("Curved cart cover has matching physical height at x=%.1f"%x,not hit.is_empty() and hit.position.distance_to(top)<0.04,"hit=%s expected=%s"%[hit.get("position",Vector3.ZERO),top])
	check("Covered loaded cart mounts and hitches normally",seat.enter() and game.hitch.toggle() and bike.cargo_mass==180)
	# An upper side beam misses the motorcycle chassis but crosses tall cargo/cover.
	var beam := BlockoutKit.box(game,Vector3(0.8,31.85,100),Vector3(0.7,0.6,0.6),Color("655645"),true)
	await frames(3)
	await press("move_forward",360)
	check("Upper cargo obstruction stops the complete towing assembly",cart.position.z>101.2 and cart.position.z<103 and absf(bike.speed)<0.2 and cart.position.distance_to(bike.position)<4.6 and cart.inventory.count("ore")==40,"cart=%s speed=%.3f gap=%.3f"%[cart.position,bike.speed,cart.position.distance_to(bike.position)])
	beam.queue_free()
	await frames(3)
	var before := cart.position
	await press("move_forward",120)
	check("Removing the upper beam restores normal towing",cart.position.distance_to(before)>4 and cart.inventory.count("ore")==40)
	await press("jump",75)
	var ramp := BlockoutKit.box(game,Vector3(0,69.5,110),Vector3(50,1,60),Color("937957"),true)
	ramp.rotation = Vector3(deg_to_rad(15),0,deg_to_rad(12))
	bike.position = Vector3(0,74,110)
	bike.rotation = Vector3.ZERO
	bike.velocity = Vector3.ZERO
	bike.speed = 0
	cart.position = bike.position+Vector3(0,0.1,3.3)
	cart.rotation = Vector3.ZERO
	cart.velocity = Vector3.ZERO
	await frames(120)
	var top := cart.visual.global_transform*Vector3(0,2.38,0)
	var up := cart.visual.global_basis.y.normalized()
	var hit := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(top+up,top-up,16))
	check("Curved collision follows the cover on compound ground",cart.is_on_floor() and up.dot(ramp.global_basis.y)>0.995 and not hit.is_empty() and hit.position.distance_to(top)<0.04)
	Input.action_press("move_forward")
	await press("move_right",120)
	check("Convex canopy preserves loaded turns on compound ground",bike.is_on_floor() and cart.is_on_floor() and bike.rotation.y< -0.3 and cart.rotation.y< -0.1 and cart.position.distance_to(bike.position)<4.6,"bike=%.3f cart=%.3f gap=%.3f"%[bike.rotation.y,cart.rotation.y,cart.position.distance_to(bike.position)])
	release()
	await press("jump",75)
	game._set_paused(true)
	var frozen := cart.canopy_collision.global_transform
	await frames(20)
	check("Pause freezes cover collision and cargo pose",cart.canopy_collision.global_transform.is_equal_approx(frozen))
	game._set_paused(false)
	game.world.enabled = false
	game.hitch.toggle()
	cart.set_physics_process(false)
	cart.position = Vector3(12,90,110)
	cart.rotation = Vector3.ZERO
	cart.visual.transform = Transform3D.IDENTITY
	cart.canopy_collision.transform = Transform3D.IDENTITY
	var post := BlockoutKit.box(game,cart.position+Vector3(0.48,2.12,-1.065),Vector3(0.04,0.06,0.04),Color("655645"),true)
	await frames(3)
	check("An upper corner obstacle rejects canopy yaw",VehicleClearance.turn_clear(cart,0,9) and not VehicleClearance.apply_turn(cart,0.15,9) and absf(cart.rotation.y)<0.001)
	post.queue_free()
	await frames(3)
	check("Removing upper cover immediately restores yaw",VehicleClearance.apply_turn(cart,0.15,9) and absf(cart.rotation.y-0.15)<0.001)
	cart.rotation = Vector3.ZERO
	post = BlockoutKit.box(game,cart.position+Vector3(-0.62,2.28,0),Vector3(0.04,0.04,0.08),Color("655645"),true)
	await frames(3)
	cart.visual.rotation.z = 0.2
	cart._sync_canopy(Transform3D.IDENTITY)
	check("Ground-pose adjustment cannot tilt the cover through an obstacle",cart.visual.transform.is_equal_approx(Transform3D.IDENTITY) and cart.canopy_collision.transform.is_equal_approx(cart.visual.transform))
	post.queue_free()
	await frames(3)
	cart.visual.rotation.z = 0.2
	cart._sync_canopy(Transform3D.IDENTITY)
	check("Clear cover resumes pose alignment",absf(cart.visual.rotation.z-0.2)<0.001 and cart.canopy_collision.transform.is_equal_approx(cart.visual.transform))
	cart.recover()
	cart.set_physics_process(true)
	cart.enabled = true
	await frames(60)
	var saveable: bool = game.saves.can_save()
	var saved: Dictionary = game.saves.snapshot()
	var saved_cart := cart.position
	cart.position.x += 12
	var restored: bool = await game.saves.restore(saved)
	await frames(30)
	top = cart.visual.global_transform*Vector3(0,2.38,0)
	hit = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(top+Vector3.UP,top-Vector3.UP,16))
	check("Save restoration retains loaded cart and physical cover",saveable and restored and cart.position.distance_to(saved_cart)<0.1 and cart.inventory.count("ore")==40 and cart.tow_vehicle==null and not hit.is_empty() and hit.position.distance_to(top)<0.04)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		var view := Camera3D.new()
		game.add_child(view)
		view.global_position = cart.position+Vector3(5,3.8,5)
		view.look_at(cart.position+Vector3.UP*1.1)
		view.current = true
		await frames(2)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/cart-canopy-m84.jpg")
	ramp.queue_free()
	platform.queue_free()
	await finish_report("cart_canopy","84 covered expedition cart",started,"--verify-cart_canopy")
