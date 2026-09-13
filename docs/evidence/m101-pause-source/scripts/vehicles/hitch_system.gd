class_name HitchSystem
extends Node
signal message(text: String)
var bike: BikeController
var cart: CargoCart
var actor: PlayerController
var seat: VehicleSeat
var backpack := Inventory.new()
var enabled: bool = false

func clear_access(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from,to,1)
	# The cart also carries the world bit so vehicles collide with it.
	# Ignore the participant bodies, while retaining intervening terrain/obstacles.
	query.exclude = [actor.get_rid(),bike.get_rid(),cart.get_rid()]
	return actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

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
	if not clear_access(actor.position+Vector3.UP*1.4,cart.position+Vector3.UP*1.1):
		message.emit("Approach the cart from a clear side.")
		return false
	if cart.tow_vehicle:
		cart.tow_vehicle = null
		bike.cargo_mass = 0
		bike.cart_attached = false
		bike.tow_cart = null
		cart.velocity = Vector3.ZERO
		message.emit("Cart detached. Cargo stays in the cart.")
		return true
	if cart.position.distance_to(bike.position+ bike.global_basis.z*3.3)>2.5 or not bike.is_on_floor() or not cart.is_on_floor() or not clear_access(bike.position+Vector3.UP*0.55,cart.position+Vector3.UP*0.55):
		message.emit("Back the bike up to the cart on clear ground.")
		return false
	cart.tow_vehicle = bike
	bike.cart_attached = true
	bike.tow_cart = cart
	bike.cargo_mass = 20+cart.inventory.mass()
	message.emit("Cart hitched. C to detach when stopped; V to load your pack.")
	return true

func can_access_cart(radius: float = 5) -> bool:
	return enabled and absf(bike.speed)<=1 and actor.position.distance_to(cart.position)<=radius and cart.is_on_floor() and (bike.is_on_floor() if seat.mounted else actor.is_on_floor()) and clear_access(actor.position+Vector3.UP*1.4,cart.position+Vector3.UP*1.1)

func move_cargo(unload: bool = false) -> int:
	if not can_access_cart(): return 0
	return cart.inventory.transfer_available(backpack) if unload else backpack.transfer_available(cart.inventory)

func _physics_process(_delta: float) -> void:
	if not enabled: return
	if Input.is_action_just_pressed("hitch_cart"): toggle()
	if Input.is_action_just_pressed("load_cargo"):
		message.emit("Moved %d items. Cart: %s" % [move_cargo(Input.is_action_pressed("sprint")),cart.inventory.summary()])
