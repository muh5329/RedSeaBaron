extends "res://tests/enemy_strike_verifier.gd"

func capture_hit(label: String) -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args(): return
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/incoming-damage-m67-%s.jpg"%label)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var feedback: IncomingDamageFeedback = game.hud.incoming_feedback
	var health: HealthComponent = game.combat.health
	var audible := not OS.has_feature("web") and DisplayServer.get_name()!="headless"
	game.audio.enabled = audible
	await duel()
	var pulses := feedback.pulses
	var requests: int = game.audio.requests
	var struck := await until(func(): return health.current<100,90)
	opponent.brain.enabled = false
	check("Real committed hostile strike triggers one bounded damage cue",struck and feedback.pulses==pulses+1 and feedback.visible and feedback.strength>0 and feedback.remaining<=IncomingDamageFeedback.DURATION and health.current==100-opponent.brain.damage)
	check("Incoming hit sound uses the existing bounded voice pool",game.audio.requests==requests+1 and game.audio.voices.size()==8 and game.audio.get_child_count()==9 and GameAudio.CLIPS.has("hurt"))
	check("Peripheral feedback cannot capture focus or mouse input",feedback.mouse_filter==Control.MOUSE_FILTER_IGNORE and feedback.focus_mode==Control.FOCUS_NONE)
	if audible: check("Native incoming hit starts an audio playback voice",game.audio.voices.any(func(voice): return voice.playing))
	await capture_hit("hostile-strike")
	var initial := feedback.strength
	await frames(10)
	check("Incoming cue fades instead of holding a full-screen flash",feedback.strength>0 and feedback.strength<initial)
	await frames(40)
	check("Incoming cue expires without changing remaining health",not feedback.visible and feedback.remaining==0 and health.current==100-opponent.brain.damage)
	pulses = feedback.pulses
	requests = game.audio.requests
	check("Rejected friendly damage produces no hit cue",not health.take_damage(15,&"player") and feedback.pulses==pulses and game.audio.requests==requests)
	health.restore()
	Input.action_press("dodge")
	await frames(12)
	var protected := health.invulnerable
	var rejected := not health.take_damage(30,&"hostile")
	release()
	check("Real dodge immunity prevents both damage and feedback",protected and rejected and health.current==100 and feedback.pulses==pulses)
	await frames(60)
	health.take_damage(14,&"hostile")
	game._set_paused(true)
	check("Pause immediately clears the incoming cue",not feedback.visible and feedback.remaining==0 and not feedback.active)
	pulses = feedback.pulses
	feedback.flash(30)
	check("Inactive feedback ignores signals while paused",not feedback.visible and feedback.pulses==pulses)
	game._set_paused(false)
	game.world.enabled = false
	health.take_damage(14,&"hostile")
	health.restore()
	check("Health restoration clears stale incoming damage",not feedback.visible and feedback.remaining==0 and health.current==100)
	game.combat.equip("RIFLE")
	var ammo: int = game.combat.ammunition
	health.take_damage(14,&"hostile")
	for down in [true,false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = get_viewport().get_final_transform()*(get_viewport().get_visible_rect().size/2)
		Input.parse_input_event(click)
		await frames(3)
	check("A real attack click passes through the active edge cue",feedback.visible and game.combat.ammunition==ammo-1)
	await frames(50)
	await place(Vector2(0,110))
	var mounted := seat.enter()
	health.take_damage(35,&"hostile")
	await frames(3)
	check("Mounted incoming damage remains visible with accurate health",mounted and feedback.visible and health.current==65 and game.hud.health_label.text=="65 / 100")
	await capture_hit("mounted")
	health.take_damage(999,&"hostile")
	await frames(140)
	check("Death recovery clears feedback and restores on-foot control",health.current==100 and not feedback.visible and not seat.mounted and player.input_enabled)
	game.audio.enabled = false
	await finish_report("incoming_damage","67 incoming damage feedback",started,"--verify-incoming_damage")
