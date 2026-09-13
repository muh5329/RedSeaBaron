extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var stream: WorldStreamer = game.world.streamer
	await place(Vector2(-12000,9000))
	bike.rotation.y = -PI/2
	await frames(80)
	await press("interact")
	await press("transform_vehicle")
	await frames(75)
	Input.action_press("move_forward")
	await frames(115)
	Input.action_press("jump")
	await frames(110)
	check("Long-range test takes off using vehicle controls",seat.mounted and bike.flight.airborne)
	var start_x := bike.position.x
	var checkpoint := floori(start_x/1000)
	var gap := false
	var lost_flight := false
	var max_resident := 0
	var frames_run := 0
	while bike.position.x<12000 and frames_run<48000:
		await frames(1)
		frames_run += 1
		gap = gap or not stream.collision_ready(bike.position)
		lost_flight = lost_flight or not bike.flight.airborne
		max_resident = maxi(max_resident,stream.chunks.size())
		if floori(bike.position.x/1000)!=checkpoint:
			checkpoint = floori(bike.position.x/1000)
			print("RSB_DISTANCE_PROGRESS x=",roundi(bike.position.x)," chunks=",stream.chunks.size()," created=",stream.created," retired=",stream.retired)
		if not bike.flight.airborne: break
	release()
	check("24 km domain crossed continuously",bike.position.x>=12000 and bike.position.x-start_x>23900,"distance=%.1f m"%(bike.position.x-start_x))
	check("Aircraft remains controllable across entire journey",seat.mounted and not lost_flight)
	check("No missing terrain under continuous long flight",not gap)
	check("Long-range terrain residency stays bounded",max_resident<=25 and stream.retired>1700,"peak=%d created=%d retired=%d"%[max_resident,stream.created,stream.retired])
	check("Long-flight chunk generation stays within stall guard",stream.largest_build_ms<100,"max build %.2f ms"%stream.largest_build_ms)
	seat.leave(true)
	await finish_report("distance","09 sustained 24 km flight",started,"--verify-distance")
