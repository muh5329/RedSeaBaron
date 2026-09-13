extends "res://tests/ui_verifier.gd"

func raw_key(code: Key, down: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	event.echo = echo
	Input.parse_input_event(event)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var food: ConsumableUse = game.consumables
	var pack: Inventory = game.hitch.backpack
	var health: HealthComponent = game.combat.health
	await place(Vector2(-48,-45))
	pack.restore_contents({})
	var orchard: ResourceSource = game.logistics.sources[0]
	var stock: int = orchard.stock.count("olive")
	await frames(20)
	await press("use_resource")
	check("Orchard input puts real food in the player's pack",pack.count("olive")==1 and orchard.stock.count("olive")==stock-1)
	health.take_damage(60,&"hostile")
	await key(KEY_X)
	check("Food input consumes one gathered olive and restores 25 HP",health.current==65 and pack.count("olive")==0 and food.meals==1)
	await capture("food-recovery")
	pack.add("olive",5)
	health.current = 90
	await key(KEY_X)
	check("Healing clamps at maximum health",health.current==100 and pack.count("olive")==4)
	await key(KEY_X)
	check("Full health keeps food unchanged",health.current==100 and pack.count("olive")==4)
	health.current = 10
	raw_key(KEY_X,true)
	await frames(60)
	raw_key(KEY_X,true,true)
	await frames(5)
	raw_key(KEY_X,false)
	check("Holding or repeating a food key does not consume repeatedly",health.current==35 and pack.count("olive")==3)
	game._set_paused(true)
	await key(KEY_X)
	game._set_paused(false)
	await frames(20)
	check("Pause rejects food and leaves no delayed consumption",health.current==35 and pack.count("olive")==3)
	Input.action_press("move_forward")
	await frames(6)
	await key(KEY_X)
	check("Moving blocks food use",health.current==35 and pack.count("olive")==3)
	release()
	await frames(20)
	await press("dodge",2)
	await key(KEY_X)
	check("Dodge blocks food use",health.current==35 and pack.count("olive")==3)
	await frames(55)
	game.combat.equip("WRENCH")
	game.combat.start_melee()
	await key(KEY_X)
	check("An attack cannot also consume food",health.current==35 and pack.count("olive")==3)
	game.combat.cancel()
	raw_key(KEY_X,true)
	raw_key(KEY_F,true)
	await frames(4)
	raw_key(KEY_X,false)
	raw_key(KEY_F,false)
	check("Same-frame attack and eating cannot both commit",health.current==35 and pack.count("olive")==3 and game.combat.state!="READY")
	game.combat.cancel()
	game.combat.equip("RIFLE")
	game.combat.ammunition = 4
	game.combat.reload_weapon()
	await key(KEY_X)
	check("Reload blocks food use",health.current==35 and pack.count("olive")==3)
	game.combat.cancel()
	pack.restore_contents({})
	game.cart.inventory.add("olive",1)
	check("Food must be in the pack, not a remote cart",not food.consume() and health.current==35 and game.cart.inventory.count("olive")==1)
	await place()
	health.current = 40
	pack.restore_contents({"olive":2})
	# Same-frame food then mount: seat processing must win ownership.
	raw_key(KEY_X,true)
	raw_key(KEY_E,true)
	await frames(4)
	raw_key(KEY_X,false)
	raw_key(KEY_E,false)
	check("Simultaneous mount and food preserves exclusive ownership",seat.mounted and health.current==40 and pack.count("olive")==2)
	seat.leave()
	await frames(30)
	var observed: Array[Dictionary] = []
	var recursive := func(): observed.append({"hp":health.current,"count":pack.count("olive"),"nested":food.consume()})
	pack.changed.connect(recursive)
	var consumed: bool = food.consume()
	pack.changed.disconnect(recursive)
	check("Food transaction is complete before notifications and rejects recursion",consumed and observed.size()==1 and observed[0].hp==65 and observed[0].count==1 and not observed[0].nested and health.current==65 and pack.count("olive")==1)
	health.current = 40
	pack.restore_contents({"olive":2})
	var attempts: Array[bool] = []
	var during_transfer := func(): attempts.append(food.consume())
	pack.changed.connect(during_transfer)
	var moved := pack.transfer_to(game.cart.inventory,"olive",1)
	pack.changed.disconnect(during_transfer)
	check("A busy inventory rolls back attempted healing without losing food",moved and attempts==[false] and health.current==40 and pack.count("olive")==1)
	await key(KEY_X)
	var saved: Dictionary = game.saves.snapshot()
	health.current = 10
	pack.add("olive",1)
	var loaded: bool = await game.saves.restore(saved)
	check("Save restore preserves consumed food and resulting health",loaded and health.current==65 and pack.count("olive")==0)
	pack.add("olive",1)
	health.take_damage(999,&"hostile")
	await key(KEY_X)
	check("Food cannot revive a dead player",health.current==0 and pack.count("olive")==1)
	await finish_report("food","35 food and player recovery",started,"--verify-food")
