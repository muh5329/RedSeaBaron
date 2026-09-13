extends "res://tests/ui_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await place(Vector2(0,80))
	await frames(20)
	var visible := 0
	for target in game.logistics.sources+game.logistics.stations+game.logistics.remote_stations:
		if target.label.is_visible_in_tree(): visible += 1
	check("Distant resource and desk actions do not clutter the world",visible==0,"visible action labels=%d"%visible)
	var blocked := ResourceSource.new()
	blocked.source_id = "prompt_blocked"
	blocked.item_id = "wood"
	blocked.title = "Blocked timber"
	blocked.position = player.position+Vector3(0,0,-2)
	game.logistics.add_child(blocked)
	game.logistics.sources.append(blocked)
	var reachable := ResourceSource.new()
	reachable.source_id = "prompt_reachable"
	reachable.item_id = "ore"
	reachable.title = "Reachable ore"
	reachable.position = player.position+Vector3(3,0,0)
	game.logistics.add_child(reachable)
	game.logistics.sources.append(reachable)
	var wall := BlockoutKit.box(game,player.position+Vector3(0,1,-1),Vector3(1.5,2,0.25),Color("937957"),true)
	await frames(20)
	check("Reachability fixture contains a blocked nearer and clear farther source",not game.logistics.can_reach(blocked) and game.logistics.can_reach(reachable))
	check("A blocked nearest source cannot starve the reachable action",game.logistics.nearest==reachable)
	var before: int = game.hitch.backpack.count("ore")
	await key(KEY_U)
	check("Real use input gathers from the reachable source",game.hitch.backpack.count("ore")==before+1 and game.hitch.backpack.count("wood")==0)
	check("Only the reachable selected source advertises its action",reachable.label.is_visible_in_tree() and not blocked.label.visible)
	game._set_paused(true)
	await frames(5)
	check("Pause clears the action prompt",game.logistics.nearest==null and not reachable.label.visible)
	game._set_paused(false)
	await frames(15)
	check("Resume restores the reachable action",game.logistics.nearest==reachable and reachable.label.visible)
	# Remove the wall, but invoke U before the periodic scan can update selection.
	wall.queue_free()
	await frames(2)
	game.logistics.scan_timer = 10
	before = game.hitch.backpack.count("wood")
	await key(KEY_U)
	check("Use input refreshes stale selection before acting",game.logistics.nearest==blocked and game.hitch.backpack.count("wood")==before+1 and not reachable.label.visible)
	game.logistics.scan_timer = 0
	player.position += Vector3(0,0,10)
	player.velocity = Vector3.ZERO
	await frames(20)
	check("Leaving range removes the advertised action",game.logistics.nearest==null and not blocked.label.visible and not reachable.label.visible)
	blocked.queue_free()
	reachable.queue_free()
	game.logistics.sources.erase(blocked)
	game.logistics.sources.erase(reachable)
	await place(Vector2(9,3))
	# Move the bike away so this remains an on-foot courier interaction.
	player.position = game.logistics.dispatch.position+Vector3(0,0.1,2.8)
	player.velocity = Vector3.ZERO
	await frames(20)
	check("A real courier desk exposes its nearby action",game.logistics.nearest==game.logistics.dispatch and game.logistics.dispatch.label.is_visible_in_tree())
	var cargo_before: int = game.hitch.backpack.count("package")+game.cart.inventory.count("package")
	await key(KEY_U)
	check("Real courier input accepts one parcel through the selected prompt",game.logistics.contract.state=="IN_TRANSIT" and game.hitch.backpack.count("package")+game.cart.inventory.count("package")==cargo_before+1)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		game.orbit.yaw = 0
		game.orbit.pitch = -0.2
		game.orbit.distance = 4.5
		game.orbit.snap()
		await frames(20)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/logistics-prompt-m72-courier.jpg")
	await finish_report("logistics_prompt","72 reachable logistics prompts",started,"--verify-logistics_prompt")
