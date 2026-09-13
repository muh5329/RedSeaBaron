class_name OrbitCamera
extends Node3D
## Orbit pivot + sphere SpringArm. World-only mask prevents self collision.
var yaw: float = 0.0
var pitch: float = -0.27
var distance: float = 6.2
var input_enabled: bool = false
var arm: SpringArm3D
var camera: Camera3D
var follow_target: Node3D
var drag_look: bool = false
var lateral_offset: float = 0.0
var heading_target: BikeController
var manual_look_remaining: float = 0

func _ready() -> void:
	arm = SpringArm3D.new()
	arm.collision_mask = 1
	arm.spring_length = distance
	arm.margin = 0.18
	var shape := SphereShape3D.new()
	shape.radius = 0.22
	arm.shape = shape
	add_child(arm)
	camera = Camera3D.new()
	camera.fov = 64.0
	camera.near = 0.12
	camera.far = 1600.0
	arm.add_child(camera)
	camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			drag_look = event.pressed
			if drag_look: manual_look_remaining = 3.0
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance - 0.5, 3.0, 9.0)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance + 0.5, 3.0, 9.0)
	if event is InputEventMouseMotion and (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or drag_look):
		manual_look_remaining = 3.0
		yaw -= event.screen_relative.x * 0.003
		pitch = clampf(pitch - event.screen_relative.y * 0.0025, -1.1, 0.35)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(follow_target):
		return
	if input_enabled:
		var horizontal := Input.get_axis("look_left","look_right")
		var vertical := Input.get_axis("look_down","look_up")
		if drag_look or horizontal!=0 or vertical!=0:
			manual_look_remaining = 3.0
		else:
			manual_look_remaining = maxf(0,manual_look_remaining-delta)
		yaw -= horizontal*delta*1.9
		pitch = clampf(pitch+vertical*delta,-1.1,0.35)
		if is_instance_valid(heading_target) and absf(heading_target.speed)>2 and manual_look_remaining<=0:
			yaw = lerp_angle(yaw,heading_target.global_rotation.y,1-exp(-delta*1.8))
	var desired := follow_target.global_position + Vector3.UP * 1.65 + Vector3.RIGHT.rotated(Vector3.UP, yaw) * lateral_offset
	global_position = global_position.lerp(desired, 1.0 - exp(-18.0 * delta))
	rotation = Vector3(pitch, yaw, 0.0)
	arm.spring_length = lerpf(arm.spring_length, distance, 1.0 - exp(-9.0 * delta))

func snap() -> void:
	if is_instance_valid(follow_target):
		global_position = follow_target.global_position + Vector3.UP * 1.65 + Vector3.RIGHT.rotated(Vector3.UP, yaw) * lateral_offset
	rotation = Vector3(pitch, yaw, 0.0)
