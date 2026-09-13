class_name WorldManager
extends Node3D
var game: Node3D
var streamer: WorldStreamer
var backdrop: WorldBackdrop
var lake_surface: WaterSurface
var core_active: bool = true
var geometry: Array[GeometryInstance3D] = []
var bodies: Array[CollisionObject3D] = []
var enabled: bool = false
var tier_timer: float = 0

func _ready() -> void:
	_collect(game.region)
	streamer = WorldStreamer.new()
	streamer.focus = game.player
	add_child(streamer)
	backdrop = WorldBackdrop.new()
	backdrop.focus = game.player
	add_child(backdrop)
	lake_surface = WaterSurface.new()
	lake_surface.water = RegionalLake.water_body()
	add_child(lake_surface)
	game.player.recovered.connect(refresh_tiers)
	# Seat/hitch listeners restore actor and cart positions before this listener runs.
	game.bike.recovered.connect(refresh_tiers)

func _collect(node: Node) -> void:
	if node is GeometryInstance3D: geometry.append(node)
	if node is CollisionObject3D: bodies.append(node)
	for child in node.get_children(): _collect(child)

func _process(delta: float) -> void:
	streamer.enabled = enabled
	if not enabled: return
	tier_timer -= delta
	if tier_timer>0: return
	tier_timer = 0.25
	refresh_tiers()

func refresh_tiers() -> void:
	# Recovery can teleport into disabled terrain. Restore collision before the next step.
	var active: bool = enabled and not game.paused
	var at: Vector3 = game.player.position
	var nearby := absf(at.x)<330 and absf(at.z)<330
	if nearby!=core_active:
		core_active = nearby
		for node in geometry: node.visible = nearby and not node.has_meta("batched_visual")
		for body in bodies: body.collision_layer = 1 if nearby else 0
		for enemy in game.enemies:
			if is_instance_valid(enemy):
				enemy.visible = nearby
				enemy.set_simulation(nearby and active)
	for worker: WorkerActor in game.workers.workers:
		worker.abstract_mode = not nearby
		worker.visible = nearby
		worker.collision_layer = 32 if nearby else 0
	game.logistics.refresh_visibility(nearby,at)
	# Parked vehicles retain state but need no distant collision ticks.
	var bike_near: bool = game.seat.mounted or game.bike.position.distance_to(at)<220
	game.bike.visible = bike_near
	game.bike.set_physics_process(bike_near and active)
	game.cart.visible = game.cart.position.distance_to(at)<220
	game.cart.enabled = game.cart.visible and active
