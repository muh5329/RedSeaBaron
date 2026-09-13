class_name WindAmbience
extends AudioStreamPlayer
## One preloaded, circular breeze voice. No per-chunk audio nodes or live synthesis.
var target_gain: float = 0.0
var sheltered: bool = false
var query_clock: float = 0.0
var context_queries: int = 0
var gain: float = 0.0

func _ready() -> void:
	stream = preload("res://assets/sfx/wind.wav").duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length()*stream.mix_rate)
	volume_db = -80

func advance(delta: float, active: bool, game: Node3D) -> void:
	if not active:
		stop()
		gain = 0
		target_gain = 0
		volume_db = -80
		query_clock = 0
		return
	query_clock -= delta
	if query_clock<=0:
		query_clock = 0.25
		context_queries += 1
		var listener: Vector3 = game.player.global_position+Vector3.UP*1.7
		var query := PhysicsRayQueryParameters3D.create(listener,listener+Vector3.UP*5,1)
		query.exclude = [game.player.get_rid(),game.bike.get_rid()]
		sheltered = not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
		var altitude: float = maxf(0,listener.y-CoastalRegion.height_at(listener.x,listener.z)-1.7)
		var exposure := clampf(altitude/45,0,1)
		target_gain = db_to_linear(lerpf(-24,-18,exposure)-(12 if sheltered else 0))
	gain = lerpf(gain,target_gain,1-exp(-delta*2))
	volume_db = linear_to_db(maxf(gain,0.0001))
	if not playing: play()
