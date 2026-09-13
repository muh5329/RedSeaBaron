class_name WaterSafety
extends Node
## Bounded water queries for the three playable bodies; no full-world Area3D.
signal message(text: String)
var player: PlayerController
var bike: BikeController
var cart: CargoCart
var seat: VehicleSeat
var sea: WaterBody
var enabled: bool = false
var player_depth: float = 0
var player_timer: float = 0
var bike_timer: float = 0
var cart_timer: float = 0
var player_recoveries: int = 0
var bike_recoveries: int = 0
var cart_recoveries: int = 0
var cart_home := Vector3.ZERO

func _ready() -> void:
	process_physics_priority = -10
	cart_home = cart.position
	player.recovered.connect(func():
		player.surface_speed_multiplier = 1
		player_depth = 0
		player_timer = 0
	)
	bike.recovered.connect(func(): bike_timer=0)

func safe_to_save() -> bool:
	return sea.depth_at(player.position)<=1.25 and sea.depth_at(bike.position)<=0.55 and sea.depth_at(cart.position)<=1.0

func _physics_process(delta: float) -> void:
	if not enabled: return
	player_depth = 0 if seat.mounted else sea.depth_at(player.position)
	player.surface_speed_multiplier = 0.6 if player_depth>0.12 else 1.0
	player_timer = player_timer+delta if player_depth>1.25 else 0.0
	if player_timer>=2:
		player_recoveries += 1
		player.recover()
		message.emit("Deep water · returned to your survey checkpoint. Pack preserved.")
	bike_timer = bike_timer+delta if sea.depth_at(bike.position)>0.55 else 0.0
	if bike_timer>=0.35:
		bike_recoveries += 1
		bike.recover()
		message.emit("Waterlogged motorcycle · returned to the workshop with attached cargo.")
	cart_timer = cart_timer+delta if not cart.tow_vehicle and sea.depth_at(cart.position)>1.0 else 0.0
	if cart_timer>=2:
		cart_recoveries += 1
		cart.position = cart_home
		cart.velocity = Vector3.ZERO
		cart_timer = 0
		message.emit("Submerged cart · recovered to the workshop. Cargo preserved.")
