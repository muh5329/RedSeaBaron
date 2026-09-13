extends "res://tests/worker_verifier.gd"

func clearance(wheel: Node3D, radius: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(wheel.global_position+Vector3.UP*2,wheel.global_position-Vector3.UP*3,1)
	query.exclude = [bike.get_rid(),game.cart.get_rid()]
	var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return INF
	return absf(hit.normal.dot(wheel.global_position-hit.position)-radius)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var cart: CargoCart = game.cart
	var ramp := BlockoutKit.box(game,Vector3(0,9,80),Vector3(24,1,24),Color("a89974"),true)
	ramp.rotation = Vector3(deg_to_rad(15),0,deg_to_rad(12))
	bike.position = Vector3(0,14,80)
	bike.velocity = Vector3.ZERO
	bike.rotation = Vector3.ZERO
	cart.position = Vector3(0,14,83.3)
	cart.velocity = Vector3.ZERO
	cart.rotation = Vector3.ZERO
	player.position = Vector3(1.65,14,80)
	player.velocity = Vector3.ZERO
	cart.inventory.add("ore",10)
	await frames(100)
	check("Slope fixture supports bike and loaded cart through real collision",bike.is_on_floor() and cart.is_on_floor() and player.is_on_floor())
	var up := ramp.global_basis.y.normalized()
	check("Bike presentation aligns with compound ground slope",bike.visual.global_basis.y.normalized().dot(up)>0.995)
	var front := clearance(bike.visual.front_wheel,0.48)
	var rear := clearance(bike.visual.rear_wheel,0.48)
	check("Both motorcycle tires remain close to the actual slope",front<0.13 and rear<0.13,"front=%.3f rear=%.3f"%[front,rear])
	var cart_visual: Variant = cart.get("visual")
	check("Cart presentation follows slope without tilting its body",cart_visual!=null and cart_visual.global_basis.y.normalized().dot(up)>0.995 and absf(cart.rotation.x)<0.001 and absf(cart.rotation.z)<0.001)
	var left := clearance(cart.wheels[0],0.44)
	var right := clearance(cart.wheels[1],0.44)
	check("Trailer tires neither bury nor float on cross slopes",left<0.13 and right<0.13,"left=%.3f right=%.3f"%[left,right])
	var mounted := seat.enter()
	var attached: bool = game.hitch.toggle()
	check("Ground-aligned loaded cart remains mountable and hitchable",mounted and attached)
	var from := bike.position
	await press("move_forward",90)
	await press("jump",60)
	check("Loaded vehicles drive and stop on the slope without flipping",bike.position.distance_to(from)>3 and bike.is_on_floor() and cart.is_on_floor() and absf(bike.rotation.x)<0.001 and absf(bike.rotation.z)<0.001 and absf(bike.speed)<0.1)
	check("Slope driving preserves drawbar distance and cargo",cart.position.distance_to(bike.position)<4.6 and cart.inventory.count("ore")==10)
	left = clearance(cart.wheels[0],0.44)
	right = clearance(cart.wheels[1],0.44)
	check("Moving trailer settles with tire contact intact",left<0.15 and right<0.15,"left=%.3f right=%.3f"%[left,right])
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		game.orbit.yaw = PI/3
		game.orbit.snap()
		await frames(8)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/vehicle-ground-native-slope.jpg")
	var detached: bool = game.hitch.toggle()
	var parked := cart.position
	await frames(120)
	check("Detached loaded cart stays parked on a traversable slope",detached and cart.position.distance_to(parked)<0.15 and cart.inventory.count("ore")==10)
	bike.recover()
	await frames(60)
	check("Recovery updates visual grounding for the new surface",clearance(bike.visual.front_wheel,0.48)<0.15 and clearance(bike.visual.rear_wheel,0.48)<0.15 and absf(bike.visual.rotation.x)<0.2)
	ramp.queue_free()
	await finish_report("vehicle_ground","27 grounded vehicle presentation and trailer contact",started,"--verify-vehicle_ground")
