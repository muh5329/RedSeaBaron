class_name GameHUD
extends CanvasLayer
signal load_requested
signal start_requested
signal pause_requested
signal resume_requested
signal map_requested
signal verify_requested
signal combat_verify_requested
signal flight_verify_requested
signal bike_verify_requested

const INK := Color("e9dfc6")
const MUTED := Color("a9bdb3")
const GOLD := Color("e4b571")
var logistics: LogisticsWorld
var workers: WorkerManager
var seat: VehicleSeat
var vehicle_panel: PanelContainer
var vehicle_status: VehicleHUD
var movement_controls: Label
var combat: PlayerCombat
var incoming_feedback: IncomingDamageFeedback
var combat_panel: PanelContainer
var combat_status: Label
var crosshair: Label
var player: PlayerController
var audio_preferences: AudioPreferences
var audio_settings: AudioSettingsPanel
var sites: Array[SurveySite] = []
var root: Control
var stamina_bar: ProgressBar
var stamina_label: Label
var health_bar: ProgressBar
var health_label: Label
var state_label: Label
var objective: Label
var region_caption: Label
var compass: Label
var prompt: PanelContainer
var prompt_text: Label
var notification: Label
var notification_time: float = 0.0
var menu: PanelContainer
var menu_title: Label
var menu_copy: Label
var start_button: Button
var verify_button: Button
var combat_verify_button: Button
var flight_verify_button: Button
var bike_verify_button: Button
var map_panel: PanelContainer
var field_notes_panel: PanelContainer
var minimap: TravelMinimap
var map_drawing: FieldMap
var map_scope: Label
var track_bike_button: Button
var track_checkpoint_button: Button
var track_cart_button: Button
var clear_waypoint_button: Button
var track_worker_buttons: Dictionary = {}
var waypoint: Variant = null
var game_active: bool = false
var verified_label: Label
var debug_label: Label
var route_complete: bool = false
var visited_count: int = 0
var hud_clock: float = 0.0

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	incoming_feedback = IncomingDamageFeedback.new()
	incoming_feedback.name = "IncomingDamageFeedback"
	incoming_feedback.health = combat.health
	root.add_child(incoming_feedback)
	var theme := Theme.new()
	theme.default_font_size = 17
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	theme.set_stylebox("normal", "Button", _style(Color("29433f"), 7, 14))
	theme.set_stylebox("hover", "Button", _style(Color("466258"), 7, 14))
	theme.set_stylebox("pressed", "Button", _style(Color("617b65"), 7, 14))
	theme.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), 7, 0, GOLD))
	root.theme = theme
	var brand := _panel(root, Vector2(28, 26), Vector2(280, 105))
	var branding := _stack(brand)
	_label(branding, "R E D   S E A   B A R O N", 21, INK)
	region_caption = _label(branding, "PORT SOLIS  /  THE FIRST MILE", 12, GOLD)
	_label(branding, "Explore · fight · deliver · automate", 12, MUTED)
	var top := CenterContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 30
	top.offset_bottom = 70
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	compass = _label(top, "W        ·        N        ·        E", 17, INK)
	var route := _panel(root, Vector2(-314, 26), Vector2(286, 184), true)
	field_notes_panel = route
	var tasks := _stack(route)
	_label(tasks, "FIELD NOTES", 12, GOLD)
	_label(tasks, "A road worth taking", 22, INK)
	objective = _label(tasks, "Stamp your route at three landmarks.\n\no  Village noticeboard\no  Olive farm\no  Coastal lookout", 15, INK)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var bottom := _panel(root, Vector2(28, -159), Vector2(280, 131), false, true)
	var stats := _stack(bottom)
	var health_row := HBoxContainer.new()
	stats.add_child(health_row)
	var health_title := _label(health_row,"HEALTH",12,MUTED)
	health_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	health_label = _label(health_row,"100 / 100",12,INK)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(242,6)
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background",_style(Color("45554a"),3,0))
	health_bar.add_theme_stylebox_override("fill",_style(Color("ca7968"),3,0))
	stats.add_child(health_bar)
	var row := HBoxContainer.new()
	stats.add_child(row)
	state_label = _label(row, "EXPLORER", 12, MUTED)
	state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stamina_label = _label(row, "100 / 100", 12, INK)
	stamina_bar = ProgressBar.new()
	stamina_bar.custom_minimum_size = Vector2(242, 6)
	stamina_bar.show_percentage = false
	stamina_bar.add_theme_stylebox_override("background", _style(Color("45554a"), 3, 0))
	stamina_bar.add_theme_stylebox_override("fill", _style(Color("d8b479"), 3, 0))
	stats.add_child(stamina_bar)
	_label(stats, "STAMINA  ·  Rest to recover", 11, MUTED)
	var controls := _panel(root, Vector2(-550, -91), Vector2(522, 63), true, true)
	var control_stack := _stack(controls)
	movement_controls = _label(control_stack, "WASD  Move     SHIFT  Sprint     SPACE  Jump     Q / CTRL  Dodge", 13, INK)
	_label(control_stack, "M  Map    B  Cargo    N  Workers    X  Eat    F6  Save    F8  Load", 12, MUTED)
	prompt = _panel(root, Vector2(-155, -178), Vector2(310, 50))
	prompt.anchor_left = 0.5
	prompt.anchor_right = 0.5
	prompt.anchor_top = 1.0
	prompt.anchor_bottom = 1.0
	prompt_text = _label(prompt, "E   Stamp route", 17, INK)
	prompt_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.visible = false
	var notify_center := CenterContainer.new()
	notify_center.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	notify_center.offset_left = -300
	notify_center.offset_right = 300
	notify_center.offset_top = 112
	notify_center.offset_bottom = 160
	notify_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(notify_center)
	notification = _label(notify_center, "", 19, GOLD)
	notification.add_theme_constant_override("outline_size", 4)
	notification.add_theme_color_override("font_outline_color", Color("263b39"))
	vehicle_panel = _panel(root, Vector2(-300, -250), Vector2(600, 117))
	vehicle_panel.anchor_left = 0.5
	vehicle_panel.anchor_right = 0.5
	vehicle_panel.anchor_top = 1
	vehicle_panel.anchor_bottom = 1
	vehicle_status = VehicleHUD.new()
	vehicle_panel.add_child(vehicle_status)
	combat_panel = _panel(root, Vector2(28, 173), Vector2(300, 108))
	combat_status = _label(combat_panel, "", 14, INK)
	crosshair = _label(root, "+", 26, INK)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_menu()
	_build_map()
	minimap = TravelMinimap.new()
	minimap.player = player
	minimap.seat = seat
	minimap.map = map_drawing
	root.add_child(minimap)
	minimap.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -244
	minimap.offset_right = -28
	minimap.offset_top = 226
	minimap.offset_bottom = 434
	debug_label = _label(root, "", 11, MUTED)
	debug_label.position = Vector2(30, 143)
	verified_label = _label(root, "", 15, GOLD)
	verified_label.position = Vector2(30, 300)
	verified_label.visible = false

func _style(color: Color, radius: int = 8, margin: int = 16, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	if border.a > 0:
		style.set_border_width_all(1)
		style.border_color = border
	return style

func _panel(parent: Control, at: Vector2, dimensions: Vector2, right: bool = false, bottom: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	panel.add_theme_stylebox_override("panel", _style(Color(0.055, 0.115, 0.11, 0.90), 8, 18))
	if right:
		panel.anchor_left = 1
		panel.anchor_right = 1
	if bottom:
		panel.anchor_top = 1
		panel.anchor_bottom = 1
	panel.offset_left = at.x
	panel.offset_top = at.y
	panel.offset_right = at.x + dimensions.x
	panel.offset_bottom = at.y + dimensions.y
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func _stack(parent: Control) -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	parent.add_child(stack)
	return stack

func _label(parent: Control, caption: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Control, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 44
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _build_menu() -> void:
	menu = _panel(root, Vector2(42, 130), Vector2(410, 450))
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(395,540)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu.add_child(scroll)
	var content := _stack(scroll)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 9)
	_label(content, "A COASTAL ADVENTURE", 12, GOLD)
	menu_title = _label(content, "Your road.\nYour enterprise.", 35, INK)
	menu_copy = _label(content, "Ride from Port Solis, trade at the quay,\nand build a working supply route. Explore the\ncoast on foot, by motorcycle, or by air.", 16, INK)
	start_button = _button(content, "Begin your journey   >", func(): start_requested.emit())
	_button(content, "Load a saved journey   [F8]",func(): load_requested.emit())
	audio_settings = AudioSettingsPanel.new()
	audio_settings.preferences = audio_preferences
	content.add_child(audio_settings)
	audio_settings.write_failed.connect(func(): notify("Audio changed for this session; preferences could not be saved."))
	_label(content, "WASD / arrows     Move relative to camera\nShift     Sprint     ·     Space     Jump\nQ / Ctrl     Dodge     ·     E     Stamp route\nRight-drag     Look     ·     Scroll     Zoom\nI J K L     Look     ·     H     Recover\n1 / 2  Weapons    F / click  Attack    G  Heavy\nTab  Lock    Alt  Aim    R  Reload    M  Map", 14, MUTED)
	verify_button = _button(content, "Run traversal checks", func(): verify_requested.emit())
	verify_button.visible = false
	combat_verify_button = _button(content, "Run combat checks", func(): combat_verify_requested.emit())
	combat_verify_button.visible = false
	flight_verify_button = _button(content, "Run flight checks", func(): flight_verify_requested.emit())
	flight_verify_button.visible = false
	bike_verify_button = _button(content, "Run bike checks", func(): bike_verify_requested.emit())
	bike_verify_button.visible = false
	_label(content, "N  Worker orders   U  Trade   B  Cargo   C  Hitch\nX  Eat an olive (+25 HP) while stopped on foot.\nT  Deploy wings; accelerate then S / back to take off.", 11, MUTED)

func _build_map() -> void:
	map_panel = _panel(root, Vector2(-280, -290), Vector2(560, 580))
	map_panel.anchor_left = 0.5
	map_panel.anchor_right = 0.5
	map_panel.anchor_top = 0.5
	map_panel.anchor_bottom = 0.5
	map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var stack := _stack(map_panel)
	_label(stack, "PORT SOLIS  /  FIELD MAP", 22, INK)
	map_scope = _label(stack, "N ^     Port Solis / local region", 13, MUTED)
	map_drawing = FieldMap.new()
	map_drawing.player = player
	map_drawing.bike = seat.bike
	map_drawing.cart = logistics.hitch.cart
	map_drawing.logistics = logistics
	map_drawing.workers = workers
	map_drawing.sites = sites
	map_drawing.waypoint_selected.connect(func(at): waypoint=at)
	map_drawing.waypoint_cleared.connect(func(): waypoint=null)
	stack.add_child(map_drawing)
	_label(stack,"Ring: checkpoint · Red: bike · Gold: cargo · Diamonds: workers",13,MUTED)
	var tracking := HBoxContainer.new()
	stack.add_child(tracking)
	track_bike_button = _button(tracking,"Track bike",func(): map_drawing.track_asset("bike"))
	track_cart_button = _button(tracking,"Track cargo",func(): map_drawing.track_asset("cart"))
	track_checkpoint_button = _button(tracking,"Checkpoint",func(): map_drawing.track_checkpoint())
	clear_waypoint_button = _button(tracking,"Clear",func(): map_drawing.clear_waypoint())
	for button in [track_bike_button,track_cart_button,track_checkpoint_button,clear_waypoint_button]:
		button.custom_minimum_size.y = 32
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var crew_tracking := HBoxContainer.new()
	stack.add_child(crew_tracking)
	if workers:
		for worker in workers.workers:
			var button := _button(crew_tracking,"Follow "+worker.worker_name,map_drawing.track_worker.bind(worker.worker_id))
			track_worker_buttons[worker.worker_id] = button
	_button(crew_tracking,"Local / world",func(): map_drawing.world_view=not map_drawing.world_view; map_drawing.queue_redraw())
	for button in crew_tracking.get_children():
		button.custom_minimum_size.y = 32
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(stack, "Return to the road   [M]", func(): map_requested.emit())
	map_panel.visible = false

func show_pause(paused: bool) -> void:
	menu.visible = paused
	if game_active:
		menu_title.text = "A moment\nby the roadside."
		menu_copy.text = "Your journey is paused.\nTake a breath, consult the map,\nor check your cargo and work orders."
		start_button.text = "Continue exploring   >"
		verify_button.visible = true
		combat_verify_button.visible = true
		bike_verify_button.visible = true
		flight_verify_button.visible = true

func show_prompt(site: SurveySite) -> void:
	prompt.visible = site != null
	if site:
		prompt_text.text = "E   " + site.prompt_action() + site.title

func notify(message: String) -> void:
	notification.text = message
	notification_time = 5.0

func update_route() -> void:
	var lines: Array[String] = []
	visited_count = 0
	for site in sites:
		if site.discovered:
			visited_count += 1
		lines.append(("+  " if site.discovered else "o  ") + site.title)
	route_complete = visited_count == sites.size()
	objective.text = ("Route complete. Keep exploring!" if route_complete else "Stamp your route.  %s / %s" % [visited_count, sites.size()]) + "\n\n" + "\n".join(lines)

func _process(delta: float) -> void:
	minimap.visible = game_active and not menu.visible and not map_panel.visible
	minimap.offset_top = maxf(226,field_notes_panel.position.y+field_notes_panel.size.y+12)
	minimap.offset_bottom = minimap.offset_top+208
	if seat:
		vehicle_panel.visible = (seat.mounted or seat.can_mount()) and not menu.visible and not map_panel.visible
		vehicle_status.navigation_target = waypoint if waypoint!=null else (logistics.contract.destination.global_position if logistics and logistics.contract.state=="IN_TRANSIT" else null)
		vehicle_status.refresh(seat)
		movement_controls.text = "WASD  Move     SHIFT  Sprint     SPACE  Jump     Q / CTRL  Dodge" if not seat.mounted else ("S  Pull up     W  Dive     SPACE  Boost     A/D  Turn" if seat.bike.flight.airborne else "W/S  Drive     A/D  Steer     C  Hitch     V / SHIFT+V  Cargo")
		combat_panel.visible = not seat.mounted and not menu.visible and not map_panel.visible
	if combat and combat.health:
		health_bar.max_value = combat.health.maximum
		health_bar.value = combat.health.current
		health_label.text = "%d / %d"%[combat.health.current,combat.health.maximum]
		combat_status.text = "%s\n%s   %s\n%s" % [combat.weapon, "PANEL OPEN" if combat.actions_blocked() else combat.state, ("%d / %d ammo" % [combat.ammunition, combat.reserve]) if combat.weapon == "RIFLE" else ("Combo %d" % combat.combo), "R  Reload · Alt  Aim · Tab  Lock" if combat.weapon == "RIFLE" else "F / Click  Swing · G  Heavy · Tab Lock"]
		crosshair.visible = combat.enabled and combat.weapon == "RIFLE" and not combat.actions_blocked()
	if player:
		stamina_bar.value = player.stamina
		stamina_label.text = "%03d / 100" % roundi(player.stamina)
		state_label.text = "RIDING" if seat and seat.mounted else ("WADING" if player.surface_speed_multiplier<1 else player.state)
	notification_time = maxf(0.0, notification_time - delta)
	notification.visible = notification_time > 0.0
	hud_clock += delta
	if hud_clock > 0.25 and player:
		hud_clock = 0
		map_drawing.refresh_tracking()
		var degrees := wrapf(rad_to_deg(-player.orbit.yaw), 0, 360)
		var cardinal: String = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][int(round(degrees / 45.0)) % 8]
		compass.text = "·     %s   %03d°     ·" % [cardinal, roundi(degrees)]
		debug_label.text = "%d FPS   ·   %.0f m from village" % [Engine.get_frames_per_second(), Vector2(player.position.x, player.position.z - 12).length()]
		if logistics and game_active:
			var at := Vector2(player.position.x,player.position.z)
			region_caption.text = "PORT SOLIS  /  THE FIRST MILE" if at.abs().x<330 and at.abs().y<330 else RegionCatalog.biome_at(at).to_upper()+"  /  OPEN COUNTRY"
			for region in RegionCatalog.all():
				if at.distance_to(region.center)<180: region_caption.text = region.title.to_upper()
			var route := logistics.selected_route()
			var remaining := at.distance_to(route.point)
			var next_action := "Courier desk: O route / U accept"
			if logistics.contract.state=="IN_TRANSIT": next_action = "Destination · %.0f m   U  Deliver"%remaining
			elif logistics.contract.state=="COMPLETED": next_action = "Courier: Shift+U repeat / O route"
			var task_text := "%s · %d crowns\n%s\n\n%s\nB  Cargo     N  Worker orders"%[route.title,route.reward,logistics.contract.state.replace("_"," "),next_action]
			if waypoint!=null:
				var offset: Vector3 = waypoint-player.position
				task_text = "%s · %.0f m\nX %.0f · Z %.0f\n\n"%[map_drawing.waypoint_title,Vector2(offset.x,offset.z).length(),waypoint.x,waypoint.z]+"Delivery · "+logistics.contract.state.replace("_"," ")+"\nM  Map / choose waypoint"
			objective.text = task_text
		if map_panel.visible:
			map_scope.text = "N ^     World · click landform labels or set a waypoint" if map_drawing.world_view else "N ^     Port Solis / 320 m local region"
			map_drawing.queue_redraw()
