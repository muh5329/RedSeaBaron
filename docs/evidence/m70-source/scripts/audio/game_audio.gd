class_name GameAudio
extends Node3D
const CLIPS := {"hurt":preload("res://assets/sfx/hurt.wav"),"rifle":preload("res://assets/sfx/rifle.wav"),"swing":preload("res://assets/sfx/swing.wav"),"hit":preload("res://assets/sfx/hit.wav"),"reload":preload("res://assets/sfx/reload.wav"),"step":preload("res://assets/sfx/step.wav"),"jump":preload("res://assets/sfx/jump.wav"),"reward":preload("res://assets/sfx/reward.wav")}
var game: Node3D
var enabled: bool = false
var voices: Array[AudioStreamPlayer3D] = []
var cursor: int = 0
var engine: AudioStreamPlayer3D
var step_clock: float = 0
var requests: int = 0

func _ready() -> void:
	for i in range(8):
		var voice := AudioStreamPlayer3D.new()
		voice.unit_size = 8
		voice.max_distance = 65
		voice.volume_db = -15
		add_child(voice)
		voices.append(voice)
	engine = AudioStreamPlayer3D.new()
	engine.stream = preload("res://assets/sfx/engine.wav").duplicate()
	engine.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	engine.stream.loop_end = int(engine.stream.get_length()*engine.stream.mix_rate)
	engine.volume_db = -28
	engine.unit_size = 8
	engine.max_distance = 65
	add_child(engine)
	game.combat.health.damaged.connect(func(_amount): cue("hurt",game.player.position))
	game.player.jumped.connect(func(): cue("jump",game.player.position))
	game.player.dodged.connect(func(): cue("swing",game.player.position))
	game.combat.swing_started.connect(func(): cue("swing",game.player.position))
	game.combat.rifle_fired.connect(func(): cue("rifle",game.player.position))
	game.combat.hit_confirmed.connect(func(): cue("hit",game.player.position))
	game.combat.reload_finished.connect(func(): cue("reload",game.player.position))
	game.logistics.contract.completed.connect(func(_reward): cue("reward",game.player.position))

func cue(id: String, at: Vector3) -> void:
	requests += 1
	if not enabled or game.paused or not CLIPS.has(id): return
	var voice := voices[cursor]
	cursor = (cursor+1)%voices.size()
	voice.stream = CLIPS[id]
	voice.position = at
	voice.play()

func _process(delta: float) -> void:
	if not enabled or game.paused:
		engine.stop()
		for voice in voices: voice.stop()
		return
	if game.seat.mounted:
		engine.position = game.bike.position
		engine.pitch_scale = 0.7+absf(game.bike.speed)/30
		if not engine.playing: engine.play()
	else:
		engine.stop()
		var speed: float = Vector2(game.player.velocity.x,game.player.velocity.z).length()
		if game.player.is_on_floor() and game.player.dodge_remaining<=0 and speed>1:
			step_clock += delta*speed
			if step_clock>2:
				step_clock = 0
				cue("step",game.player.position)
