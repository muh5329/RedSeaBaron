class_name HitchSystem
extends Node
signal message(text: String)
var bike: BikeController
var cart: CargoCart
var actor: PlayerController
var seat: VehicleSeat
var backpack := Inventory.new()
var enabled: bool = false

func _ready() -> void:
	bike.recovered.connect(func():
		if cart.tow_vehicle:
			cart.position = bike.position+Vector3(0,0.15,3.3)
			cart.rotation = bike.rotation
			cart.velocity = Vector3.ZERO
	)

func toggle() -> bool:
	if not enabled or absf(bike.speed)>1 or bike.flight.airborne or bike.transformation.mode!="BIKE":
		message.emit("Stop in bike mode to use the hitch.")
		return false
	if not seat.mounted and actor.position.distance_to(cart.position)>4:
		message.emit("Approach the cart to use its hitch.")
		return false
	if cart.tow_vehicle:
		cart.tow_vehicle = null
		bike.cargo_mass = 0
		bike.cart_attached = false
		bike.tow_cart = null
		cart.velocity = Vector3.ZERO
		message.emit("Cart detached. Cargo stays in the cart.")
		return true
	if cart.position.distance_to(bike.position+ bike.global_basis.z*3.3)>2.5 or not cart.is_on_floor() or not DamageSystem.clear_line(bike.get_world_3d(),bike.position+Vector3.UP*1.6,cart.position+Vector3.UP*1.6):
		message.emit("Back the bike up to the cart on clear ground.")
		return false
	cart.tow_vehicle = bike
	bike.cart_attached = true
	bike.tow_cart = cart
	bike.cargo_mass = 20+cart.inventory.mass()
	message.emit("Cart hitched. C to detach when stopped; V to load your pack.")
	return true

func move_cargo(unload: bool = false) -> int:
	if not enabled or absf(bike.speed)>1 or actor.position.distance_to(cart.position)>5: return 0
	return cart.inventory.transfer_available(backpack) if unload else backpack.transfer_available(cart.inventory)

func _physics_process(_delta: float) -> void:
	if not enabled: return
	if Input.is_action_just_pressed("hitch_cart"): toggle()
	if Input.is_action_just_pressed("load_cargo"):
		message.emit("Moved %d items. Cart: %s" % [move_cargo(Input.is_action_pressed("sprint")),cart.inventory.summary()])
