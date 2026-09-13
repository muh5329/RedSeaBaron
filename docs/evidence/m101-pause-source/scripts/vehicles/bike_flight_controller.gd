class_name BikeFlightController
extends RefCounted
var bike: BikeController
var airborne: bool = false
var pitch: float = 0.0
var altitude: float = 0.0
var takeoffs: int = 0
var landings: int = 0

func compute_velocity(delta: float) -> bool:
	altitude = maxf(0,bike.position.y-CoastalRegion.height_at(bike.position.x,bike.position.z))
	if bike.transformation.mode != "AIRCRAFT":
		return false
	if not airborne:
		if bike.input_enabled and Input.is_action_pressed("move_back") and not Input.is_action_pressed("sprint") and bike.speed>=12 and bike.is_on_floor():
			airborne = true
			takeoffs += 1
			bike.velocity.y = 5
			pitch = 0.22
			bike.floor_snap_length = 0
		else:
			return false
	var boosting := bike.input_enabled and Input.is_action_pressed("jump")
	var turn := Input.get_axis("move_left","move_right") if bike.input_enabled else 0.0
	var climb := Input.get_axis("move_forward","move_back") if bike.input_enabled else 0.0
	var load_factor := 1.0/(1.0+bike.cargo_mass/160.0)
	var braking := bike.input_enabled and Input.is_action_pressed("sprint")
	var target_speed := (5.0 if braking else 34.0 if boosting else 22.0)*load_factor
	bike.speed = move_toward(bike.speed,target_speed,delta*5)
	var target_pitch := climb*0.55
	# Flare near actual ground so the nose propeller cannot hold the wheels aloft.
	if climb<0 and bike.velocity.y<0:
		var floor_hit := bike.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(bike.position+Vector3.UP,bike.position-Vector3.UP*4,1,[bike.get_rid()]))
		if not floor_hit.is_empty(): target_pitch = maxf(target_pitch,-0.06)
	pitch = move_toward(pitch,target_pitch,delta*1.5)
	# Keep room above highland runways as well as sea-level terrain.
	if altitude>110 and bike.position.y>115:
		pitch = minf(pitch, -0.1)
	bike.try_turn(bike.rotation.y-turn*delta*0.95)
	var forward := -bike.global_basis.z
	bike.velocity.x = forward.x*bike.speed*cos(pitch)
	bike.velocity.z = forward.z*bike.speed*cos(pitch)
	var stall_sink := -maxf(0,12-bike.speed)*0.7
	bike.velocity.y = lerpf(bike.velocity.y,sin(pitch)*bike.speed+stall_sink,1-exp(-delta*3))
	bike.steering = turn
	return true

func after_move() -> void:
	if airborne and bike.is_on_floor() and bike.velocity.y<=0.3 and _undercarriage_supported():
		airborne = false
		landings += 1
		pitch = 0
		bike.floor_snap_length = 0.9
	if airborne and bike.is_on_wall():
		# Collision removes speed rather than allowing flight through terrain.
		bike.speed = minf(bike.speed,Vector2(bike.velocity.x,bike.velocity.z).length())

func _undercarriage_supported() -> bool:
	# The upright chassis defines physical wheel support; visual flight pitch is
	# decorative. A floor contact from a wing must not authorize folding/saving.
	for axle in [-0.97, 0.97]:
		var query := PhysicsRayQueryParameters3D.create(
			bike.to_global(Vector3(0,0.35,axle)),
			bike.to_global(Vector3(0,-0.4,axle)),1,[bike.get_rid()])
		var hit := bike.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.normal.dot(Vector3.UP)>=cos(bike.floor_max_angle):
			return true
	return false

func reset() -> void:
	airborne = false
	pitch = 0
	bike.floor_snap_length = 0.9
