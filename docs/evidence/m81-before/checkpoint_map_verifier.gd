extends "res://tests/equipment_map_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await frames(60)
	await key(KEY_M)
	var button: Button
	for candidate in game.hud.map_panel.find_children("*","Button",true,false):
		if candidate.text=="Checkpoint": button = candidate
	check("Map offers an explicit recovery checkpoint target",button!=null)
	await finish_report("checkpoint_map","81 recovery checkpoint guidance",started,"--verify-checkpoint_map")
