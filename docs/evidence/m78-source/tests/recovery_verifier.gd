extends "res://tests/worker_verifier.gd"

func distant_bike() -> void:
	var at := Vector2(0,950)
	player.position = Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+4,at.y)
	player.velocity = Vector3.ZERO
	await frames(90)
	await place(at)
	await press("interact")

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await distant_bike()
	game.cart.position = bike.position+bike.global_basis.z*3.3+Vector3.UP*0.15
	game.cart.rotation = bike.rotation
	game.cart.inventory.add("wood",3)
	game.world.refresh_tiers()
	await frames(30)
	await press("hitch_cart")
	check("Recovery fixture mounts a loaded distant vehicle",seat.mounted and bike.cart_attached and not game.world.core_active)
	game.world.tier_timer = 0.25
	await press("reset_player")
	check("Mounted recovery activates home collision immediately",game.world.core_active and game.world.bodies.all(func(b): return b.collision_layer==1))
	await frames(30)
	check("Recovered bike and cart settle on home terrain",bike.is_on_floor() and game.cart.is_on_floor() and bike.position.distance_to(bike.home)<1,"bike=%s cart=%s"%[bike.position,game.cart.position])
	check("Mounted recovery preserves seat and cargo",seat.mounted and game.cart.tow_vehicle==bike and game.cart.inventory.count("wood")==3 and not player.visible)
	if not game.world.core_active or not bike.is_on_floor():
		await finish_report("recovery","18 distant vehicle recovery lifecycle",started,"--verify-recovery")
		return
	await press("hitch_cart")
	seat.leave()
	await distant_bike()
	await press("transform_vehicle")
	await frames(75)
	Input.action_press("move_forward")
	await frames(110)
	Input.action_press("jump")
	await frames(100)
	release()
	check("Airborne death fixture uses actual distant takeoff",seat.mounted and bike.flight.airborne and not game.world.core_active)
	game.world.tier_timer = 0.25
	game.combat.health.take_damage(999,&"hostile")
	check("Airborne death releases seat onto active home terrain",not seat.mounted and game.world.core_active and not bike.flight.airborne)
	await frames(30)
	check("Death recovery cannot fall through unloaded home",player.is_on_floor() and bike.is_on_floor(),"player=%s bike=%s"%[player.position,bike.position])
	await frames(130)
	check("Death recovery restores live controls without duplicating cargo",game.combat.health.current==100 and player.input_enabled and player.visible and game.cart.inventory.count("wood")==3)
	await finish_report("recovery","18 distant vehicle recovery lifecycle",started,"--verify-recovery")
