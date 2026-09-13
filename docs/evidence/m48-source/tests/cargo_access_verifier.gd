extends "res://tests/cart_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var hitch: HitchSystem = game.hitch
	var cart: CargoCart = game.cart
	await place(Vector2(0,80))
	cart.position = bike.position+Vector3(0,0.2,3.3)
	cart.rotation = Vector3.ZERO
	cart.velocity = Vector3.ZERO
	player.position = cart.position+Vector3(3,0.2,0)
	await frames(30)
	hitch.backpack.add("wood",5)
	var wall := BlockoutKit.box(game,cart.position+Vector3(1.5,1.5,0),Vector3(0.3,3,4),Color("756957"),true)
	await frames(3)
	var moved := hitch.move_cargo()
	check("Solid wall blocks loading cargo without consuming inventory",moved==0 and hitch.backpack.count("wood")==5 and cart.inventory.mass()==0)
	# Restore test contents after a failing baseline to inspect the remaining guards independently.
	cart.inventory.restore_contents({})
	hitch.backpack.restore_contents({"wood":5})
	wall.queue_free()
	await frames(3)
	check("Clear nearby access loads the same cargo",hitch.move_cargo()==5 and cart.inventory.count("wood")==5)
	wall = BlockoutKit.box(game,cart.position+Vector3(1.5,1.5,0),Vector3(0.3,3,4),Color("756957"),true)
	await frames(3)
	check("Solid wall also blocks unloading",hitch.move_cargo(true)==0 and cart.inventory.count("wood")==5)
	wall.queue_free()
	cart.inventory.restore_contents({"wood":5})
	hitch.backpack.restore_contents({})
	await frames(3)
	player.position = bike.position+Vector3(1.6,0.15,0)
	await frames(20)
	await press("interact")
	check("Mounted rider can access rear cargo without self-occlusion",seat.mounted and hitch.move_cargo(true)==5)
	cart.inventory.restore_contents({"wood":5})
	hitch.backpack.restore_contents({})
	# Actual upward motion clears floor contact; speed stays zero so speed-only guards fail.
	bike.velocity.y = 6
	await frames(5)
	check("Stationary airborne bike cannot attach a grounded cart",not bike.is_on_floor() and not hitch.toggle() and not bike.cart_attached)
	if bike.cart_attached: hitch.toggle()
	check("Airborne rider cannot transfer ground cargo",hitch.move_cargo(true)==0 and cart.inventory.count("wood")==5)
	cart.inventory.restore_contents({"wood":5})
	hitch.backpack.restore_contents({})
	await frames(70)
	# A knee-high obstacle intersects the real drawbar but leaves the old 1.6 m ray clear.
	wall = BlockoutKit.box(game,bike.position+Vector3(0,0.48,1.9),Vector3(3,0.96,0.35),Color("756957"),true)
	await frames(3)
	check("Low drawbar obstacle rejects hitching",not hitch.toggle() and not bike.cart_attached)
	if bike.cart_attached: hitch.toggle()
	wall.queue_free()
	await frames(3)
	check("Removing obstacle permits grounded hitching",hitch.toggle() and bike.cart_attached and cart.inventory.count("wood")==5)
	await press("move_forward",80)
	release()
	await press("jump",60)
	check("Loaded cart still follows after guarded attachment",cart.travelled>2 and cart.position.distance_to(bike.position)<4.6 and cart.inventory.count("wood")==5)
	hitch.toggle()
	seat.leave(true)
	var warehouse: Storage = game.logistics.warehouse
	player.position = warehouse.position+Vector3(0,0.2,2)
	player.velocity = Vector3.ZERO
	cart.position = player.position+Vector3(3,0.2,0)
	cart.velocity = Vector3.ZERO
	await frames(30)
	wall = BlockoutKit.box(game,player.position+Vector3(1.5,1.5,0),Vector3(0.3,3,4),Color("756957"),true)
	await frames(3)
	check("Warehouse interaction cannot bypass cart access obstruction",not game.logistics.use_station(warehouse) and cart.inventory.count("wood")==5 and warehouse.inventory.mass()==0)
	wall.queue_free()
	cart.inventory.restore_contents({"wood":5})
	warehouse.inventory.restore_contents({})
	await frames(3)
	check("Clear warehouse interaction accepts accessible cart goods",game.logistics.use_station(warehouse) and warehouse.inventory.count("wood")==5 and cart.inventory.mass()==0)
	await finish_report("cargo_access","23 physical cargo access guards",started,"--verify-cargo_access")
