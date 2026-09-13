class_name InputBindings
extends RefCounted

static func install() -> void:
	var bindings := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"delivery_route": [KEY_O],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"sprint": [KEY_SHIFT], "jump": [KEY_SPACE], "dodge": [KEY_CTRL, KEY_Q],
		"interact": [KEY_E], "pause_game": [KEY_ESCAPE], "map": [KEY_M],
		"reset_player": [KEY_H], "look_left": [KEY_J], "look_right": [KEY_L],
		"look_up": [KEY_I], "look_down": [KEY_K], "verify": [KEY_F9],
		"equip_wrench": [KEY_1], "equip_rifle": [KEY_2], "attack": [KEY_F],
		"buy_ammunition": [KEY_P], "save_game": [KEY_F6], "load_game": [KEY_F8], "workers": [KEY_N], "job_routine": [KEY_0], "job_gather": [KEY_3], "job_farm": [KEY_4], "job_delivery": [KEY_5], "job_shop": [KEY_6], "job_transport": [KEY_7], "job_retry": [KEY_8], "job_cancel": [KEY_9], "hitch_cart": [KEY_C], "load_cargo": [KEY_V], "use_resource": [KEY_U], "inventory": [KEY_B], "transform_vehicle": [KEY_T], "heavy_attack": [KEY_G], "reload": [KEY_R], "aim": [KEY_ALT], "lock_target": [KEY_TAB]
	}
	for action: String in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", click)
