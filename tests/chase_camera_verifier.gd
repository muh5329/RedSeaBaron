extends "res://tests/worker_verifier.gd"

func heading_error() -> float:
	return absf(wrapf(game.orbit.yaw-bike.rotation.y,-PI,PI))

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var camera: OrbitCamera = game.orbit
	await place(Vector2(-60,100))
	bike.rotation.y = PI
	seat.enter()
	check("Mounted camera follows the active vehicle anchor",seat.mounted and camera.follow_target==bike.camera_anchor)
	Input.action_press("move_forward")
	await frames(150)
	check("Driving naturally brings camera behind the vehicle",heading_error()<0.12,"heading error=%.3f"%heading_error())
	var yaw_before := camera.yaw
	await press("look_right",30)
	var looked := camera.yaw
	check("Keyboard free look remains responsive while driving",absf(wrapf(looked-yaw_before,-PI,PI))>0.7)
	await frames(60)
	check("Manual look has a grace period without camera fighting input",absf(wrapf(camera.yaw-looked,-PI,PI))<0.02)
	await frames(240)
	check("Chase camera resumes smoothly after free-look grace",heading_error()<0.12,"heading error=%.3f"%heading_error())
	await press("move_right",40)
	await frames(60)
	check("Camera follows an actual steering turn",heading_error()<0.16,"heading error=%.3f"%heading_error())
	game._set_paused(true)
	var paused_yaw := camera.yaw
	var paused_at := bike.position
	await frames(45)
	check("Pause freezes vehicle and camera steering",absf(camera.yaw-paused_yaw)<0.001 and bike.position.distance_to(paused_at)<0.001)
	game._set_paused(false)
	release()
	await press("jump",90)
	# Inject complete mouse events through the engine input path.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	click.position = Vector2(640,400)
	Input.parse_input_event(click)
	await frames(2)
	var drag_started := camera.drag_look
	yaw_before = camera.yaw
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100,0)
	motion.screen_relative = Vector2(100,0)
	motion.button_mask = MOUSE_BUTTON_MASK_RIGHT
	motion.position = Vector2(740,400)
	Input.parse_input_event(motion)
	await frames(2)
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = false
	click.position = Vector2(740,400)
	Input.parse_input_event(click)
	await frames(2)
	check("Right-drag orbit works on a stopped vehicle",absf(wrapf(camera.yaw-yaw_before,-PI,PI)+0.3)<0.01,"delta=%.3f drag_started=%s enabled=%s viewport=%s"%[wrapf(camera.yaw-yaw_before,-PI,PI),drag_started,camera.input_enabled,get_viewport().get_visible_rect().size])
	looked = camera.yaw
	await frames(240)
	check("Stopped vehicle preserves the chosen camera view",absf(wrapf(camera.yaw-looked,-PI,PI))<0.01)
	var saved: Dictionary = game.saves.snapshot()
	seat.leave()
	var loaded: bool = await game.saves.restore(saved)
	check("Save restores mounted camera orientation exactly",loaded and seat.mounted and absf(wrapf(camera.yaw-looked,-PI,PI))<0.01)
	Input.action_press("move_forward")
	await frames(150)
	check("Restored mounted camera resumes heading follow when driving",heading_error()<0.12)
	release()
	await press("jump",90)
	var exited := seat.leave()
	await press("look_left",20)
	looked = camera.yaw
	await frames(90)
	check("Dismount returns independent on-foot orbit",exited and camera.follow_target==player and absf(wrapf(camera.yaw-looked,-PI,PI))<0.01)
	await finish_report("chase_camera","28 vehicle chase camera with free look",started,"--verify-chase_camera")
