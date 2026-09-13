extends Node3D
## Composition root. Systems are wired by references and signals here.
const Verifier = preload("res://tests/traversal_verifier.gd")
const CombatVerifier = preload("res://tests/combat_verifier.gd")
const AIVerifier = preload("res://tests/ai_verifier.gd")
const EconomyVerifier = preload("res://tests/economy_verifier.gd")
const HighlandVerifier = preload("res://tests/highland_verifier.gd")
const RegionVerifier = preload("res://tests/region_verifier.gd")
const RecoveryVerifier = preload("res://tests/recovery_verifier.gd")
const FeedbackVerifier = preload("res://tests/feedback_verifier.gd")
const IntegrationVerifier = preload("res://tests/integration_verifier.gd")
const ResumeVerifier = preload("res://tests/resume_verifier.gd")
const UIVerifier = preload("res://tests/ui_verifier.gd")
const SaveVerifier = preload("res://tests/save_verifier.gd")
const DistanceVerifier = preload("res://tests/distance_verifier.gd")
const WorldVerifier = preload("res://tests/world_verifier.gd")
const WorkerVerifier = preload("res://tests/worker_verifier.gd")
const LogisticsVerifier = preload("res://tests/logistics_verifier.gd")
const CartVerifier = preload("res://tests/cart_verifier.gd")
const FlightVerifier = preload("res://tests/flight_verifier.gd")
const BikeVerifier = preload("res://tests/bike_verifier.gd")
var audio: GameAudio
var saves: SaveSystem
var world: WorldManager
var regions: RegionManager
var workers: WorkerManager
var logistics: LogisticsWorld
var cart: CargoCart
var hitch: HitchSystem
var bike: BikeController
var seat: VehicleSeat
var combat: PlayerCombat
var enemies: Array[EnemyActor] = []
var region: CoastalRegion
var player: PlayerController
var orbit: OrbitCamera
var interaction: InteractionController
var hud: GameHUD
var sites: Array[SurveySite] = []
var paused: bool = true
var started: bool = false
var verification_running: bool = false

func _ready() -> void:
	InputBindings.install()
	region = CoastalRegion.new()
	region.name = "CoastalRegion"
	add_child(region)
	player = PlayerController.new()
	player.name = "Player"
	add_child(player)
	player.spawn_position = Vector3(0, CoastalRegion.height_at(0, 12) + 0.12, 12)
	player.position = player.spawn_position
	orbit = OrbitCamera.new()
	orbit.name = "OrbitCamera"
	orbit.follow_target = player
	add_child(orbit)
	player.orbit = orbit
	orbit.snap()
	combat = PlayerCombat.new()
	combat.actor = player
	combat.orbit = orbit
	add_child(combat)
	_spawn_camp()
	_spawn_bike()
	_spawn_cart()
	logistics = LogisticsWorld.new()
	logistics.actor = player
	logistics.hitch = hitch
	logistics.seat = seat
	logistics.combat = combat
	add_child(logistics)
	workers = WorkerManager.new()
	workers.logistics = logistics
	add_child(workers)
	for enemy in enemies: enemy.brain.navigation = workers.navigation
	_add_site("village", "Village noticeboard", "Port Solis: a starting point for bigger journeys.", Vector2(0, -2))
	_add_site("farm", "Olive farm", "The terraces will supply future delivery routes.", Vector2(-48, -57))
	_add_site("lookout", "Coastal lookout", "A flight route waits beyond the limestone arch.", Vector2(48, -91))
	interaction = InteractionController.new()
	interaction.actor = player
	interaction.sites = sites
	add_child(interaction)
	hud = GameHUD.new()
	hud.seat = seat
	hud.logistics = logistics
	hud.combat = combat
	hud.player = player
	hud.sites = sites
	add_child(hud)
	seat.changed.connect(func(): _set_paused(paused))
	seat.message.connect(hud.notify)
	bike.message.connect(hud.notify)
	hitch.message.connect(hud.notify)
	logistics.message.connect(hud.notify)
	workers.message.connect(hud.notify)
	logistics.panel_opened.connect(func(): workers.panel.visible=false)
	hud.flight_verify_requested.connect(run_flight_verifier)
	hud.start_requested.connect(_begin)
	hud.load_requested.connect(_load_saved)
	hud.map_requested.connect(_toggle_map)
	hud.verify_requested.connect(run_verifier)
	hud.combat_verify_requested.connect(run_combat_verifier)
	hud.bike_verify_requested.connect(run_bike_verifier)
	interaction.prompt_changed.connect(hud.show_prompt)
	interaction.interacted.connect(func(site: SurveySite):
		player.stamina = player.config.stamina_max
		player.spawn_position = site.global_position + Vector3(0, 0.2, 1.5)
		hud.notify(site.description)
	)
	player.recovered.connect(func(): hud.notify("Returned to your last survey station."))
	hud.update_route()
	world = WorldManager.new()
	world.game = self
	add_child(world)
	regions = RegionManager.new()
	regions.actor = player
	add_child(regions)
	regions.discovered_region.connect(func(region: RegionDefinition): hud.notify("Discovered: "+region.title))
	hud.map_drawing.regions = regions
	saves = SaveSystem.new()
	saves.game = self
	add_child(saves)
	saves.message.connect(hud.notify)
	audio = GameAudio.new()
	audio.game = self
	add_child(audio)
	_set_paused(true)
	print("RSB_READY | Godot ", Engine.get_version_info().string, " | region=320m | terrain_tiles=25 | streamed_window=25")
	var query := str(JavaScriptBridge.eval("window.location.search",true)) if OS.has_feature("web") else ""
	var suites := {"1":run_verifier,"combat":run_combat_verifier,"bike":run_bike_verifier,"flight":run_flight_verifier,"cart":run_cart_verifier,"logistics":run_logistics_verifier,"worker":run_worker_verifier,"world":run_world_verifier,"distance":run_distance_verifier,"save":run_save_verifier,"ui":run_ui_verifier,"resume":run_resume_verifier,"integration":run_integration_verifier,"feedback":run_feedback_verifier,"ai":run_ai_verifier,"economy":run_economy_verifier,"highland":run_highland_verifier,"region":run_region_verifier,"recovery":run_recovery_verifier}
	for id: String in suites:
		var flag := "--verify" if id=="1" else "--verify-"+id
		if flag in OS.get_cmdline_user_args() or query.contains("verify="+id):
			suites[id].call_deferred()
			break

func _add_site(id: String, title: String, description: String, at: Vector2) -> void:
	var site := SurveySite.new()
	site.site_id = id
	site.title = title
	site.description = description
	site.position = Vector3(at.x, CoastalRegion.height_at(at.x, at.y) + 0.08, at.y)
	add_child(site)
	sites.append(site)
	site.visited.connect(func(_site: SurveySite):
		hud.update_route()
		if hud.route_complete:
			hud.notify("First mile complete. All three stations surveyed.")
	)

func _begin() -> void:
	if audio: audio.enabled = true
	started = true
	hud.game_active = true
	hud.map_panel.visible = false
	_set_paused(false)
	combat.block_until_released = true
	# Embedded Chromium can reject pointer lock. Web uses drag / keyboard look.
	_capture_mouse()

func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if OS.has_feature("web") else Input.MOUSE_MODE_CAPTURED

func _set_paused(value: bool) -> void:
	paused = value
	if world: world.enabled = not value
	if regions: regions.enabled = not value
	player.set_controls(not value and not seat.mounted and combat.health.current > 0)
	player.set_physics_process(not value and not seat.mounted)
	orbit.input_enabled = not value
	orbit.drag_look = false
	interaction.enabled = not value and not seat.mounted
	combat.set_enabled(not value and not seat.mounted)
	seat.enabled = not value
	bike.input_enabled = not value and seat.mounted
	bike.set_physics_process(not value and (seat.mounted or bike.position.distance_to(player.position)<220))
	hitch.enabled = not value
	logistics.enabled = not value
	workers.enabled = not value
	for worker in workers.workers: worker.enabled = not value
	cart.enabled = not value and cart.position.distance_to(player.position)<220
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.set_simulation(not value and (world==null or world.core_active))
	hud.show_pause(value)
	if value:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _toggle_map() -> void:
	if not started or verification_running:
		return
	var opening := not hud.map_panel.visible
	_set_paused(opening)
	hud.menu.visible = false
	hud.map_panel.visible = opening
	if opening:
		hud.map_drawing.world_view = absf(player.position.x)>160 or absf(player.position.z)>160
	print("RSB_UI | map_open=", opening)
	if not opening:
		_capture_mouse()

func _input(event: InputEvent) -> void:
	# Global shortcuts must run before GUI focus can consume key events.
	if event.is_echo():
		return
	if verification_running:
		return
	if event.is_action_pressed("pause_game") and started:
		hud.map_panel.visible = false
		_set_paused(not paused)
		if not paused:
			_capture_mouse()
	elif event.is_action_pressed("map"):
		_toggle_map()
	elif event.is_action_pressed("verify"):
		run_verifier()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and started and not verification_running and is_instance_valid(hud):
		_set_paused(true)

func run_verifier() -> void:
	await _run_suite(Verifier)

func _spawn_camp() -> void:
	for info in [[Vector2(-62, 14), "Raider"], [Vector2(-73, -2), "Cinder beast"], [Vector2(-79, 7), "Raider"]]:
		var enemy := EnemyActor.new()
		enemy.kind = info[1]
		enemy.target = player
		enemy.position = Vector3(info[0].x, CoastalRegion.height_at(info[0].x, info[0].y) + 0.1, info[0].y)
		enemy.home = enemy.position
		add_child(enemy)
		enemies.append(enemy)
	var sign_at := Vector3(-34, CoastalRegion.height_at(-34, 12), 12)
	BlockoutKit.box(region, sign_at + Vector3.UP, Vector3(0.15, 2, 0.15), Color("765943"))
	BlockoutKit.box(region, sign_at + Vector3.UP * 1.7, Vector3(3.8, 0.8, 0.2), Color("753f30"))
	BlockoutKit.label(region, "DANGER  <  RAIDER CAMP", sign_at + Vector3(0, 1.7, 0.13), 23)

func run_combat_verifier() -> void:
	await _run_suite(CombatVerifier)

func _spawn_bike() -> void:
	bike = BikeController.new()
	bike.position = Vector3(10, CoastalRegion.height_at(10, -10) + 0.15, -10)
	bike.home = bike.position
	add_child(bike)
	seat = VehicleSeat.new()
	seat.actor = player
	seat.bike = bike
	seat.orbit = orbit
	seat.combat = combat
	add_child(seat)

func run_bike_verifier() -> void:
	await _run_suite(BikeVerifier)

func run_flight_verifier() -> void:
	await _run_suite(FlightVerifier)

func _spawn_cart() -> void:
	cart = CargoCart.new()
	cart.position = bike.position+Vector3(0,0.2,3.3)
	add_child(cart)
	hitch = HitchSystem.new()
	hitch.bike = bike
	hitch.cart = cart
	hitch.actor = player
	hitch.seat = seat
	add_child(hitch)
func run_cart_verifier() -> void:
	await _run_suite(CartVerifier)

func run_logistics_verifier() -> void:
	await _run_suite(LogisticsVerifier)

func run_worker_verifier() -> void:
	await _run_suite(WorkerVerifier)

func run_world_verifier() -> void:
	await _run_suite(WorldVerifier)

func run_distance_verifier() -> void:
	await _run_suite(DistanceVerifier)

func _run_suite(suite: Script) -> void:
	if verification_running: return
	verification_running = true
	started = true
	hud.game_active = true
	hud.map_panel.visible = false
	_set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var verifier: Node = suite.new()
	add_child(verifier)
	await verifier.run(self)
	verification_running = false
	verifier.queue_free()

func run_save_verifier() -> void:
	await _run_suite(SaveVerifier)

func run_ui_verifier() -> void:
	await _run_suite(UIVerifier)

func run_resume_verifier() -> void:
	await _run_suite(ResumeVerifier)

func _load_saved() -> void:
	if saves.busy: return
	_begin()
	if not await saves.load_game(): hud.notify("No valid saved journey was found. F6 saves while stopped on ground.")

func run_integration_verifier() -> void:
	await _run_suite(IntegrationVerifier)

func run_feedback_verifier() -> void:
	await _run_suite(FeedbackVerifier)

func run_ai_verifier() -> void:
	await _run_suite(AIVerifier)

func run_economy_verifier() -> void:
	await _run_suite(EconomyVerifier)

func run_highland_verifier() -> void:
	await _run_suite(HighlandVerifier)

func run_region_verifier() -> void:
	await _run_suite(RegionVerifier)

func run_recovery_verifier() -> void:
	await _run_suite(RecoveryVerifier)
