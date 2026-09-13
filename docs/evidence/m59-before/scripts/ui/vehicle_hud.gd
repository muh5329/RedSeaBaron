class_name VehicleHUD
extends VBoxContainer
## Presentation of controller state; flight and seat systems own the rules.
const CREAM := Color("e9dfc6")
const GOLD := Color("e4b571")
const MUTED := Color("a9bdb3")
const WARNING := Color("edaa76")
var heading: Label
var condition: Label
var controls: Label
var speed_bar: ProgressBar
var normal_fill: StyleBoxFlat
var warning_fill: StyleBoxFlat
var warning_active: bool = false

func _ready() -> void:
	add_theme_constant_override("separation",5)
	heading = _line(18,CREAM)
	condition = _line(13,GOLD)
	speed_bar = ProgressBar.new()
	speed_bar.custom_minimum_size.y = 4
	speed_bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("45554a")
	background.set_corner_radius_all(2)
	normal_fill = background.duplicate()
	normal_fill.bg_color = GOLD
	warning_fill = background.duplicate()
	warning_fill.bg_color = WARNING
	speed_bar.add_theme_stylebox_override("background",background)
	speed_bar.add_theme_stylebox_override("fill",normal_fill)
	add_child(speed_bar)
	controls = _line(12,MUTED)

func _line(size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	add_child(label)
	return label

func refresh(seat: VehicleSeat) -> void:
	var bike := seat.bike
	var mode := bike.transformation.mode
	var flying := bike.flight.airborne
	var slow := flying and bike.speed<12
	heading.text = "%s   %03d km/h"%["AIRCRAFT" if mode=="AIRCRAFT" else "MOTORCYCLE",roundi(absf(bike.speed)*3.6)]
	condition.visible = seat.mounted
	speed_bar.visible = seat.mounted
	controls.visible = seat.mounted
	speed_bar.max_value = 34 if mode=="AIRCRAFT" else bike.maximum_speed
	speed_bar.value = absf(bike.speed)
	if warning_active!=slow:
		warning_active = slow
		speed_bar.add_theme_stylebox_override("fill",warning_fill if slow else normal_fill)
		condition.add_theme_color_override("font_color",WARNING if slow else GOLD)
	if not seat.mounted:
		heading.text = "E   Ride the motorcycle"
		return
	if mode in ["DEPLOYING","FOLDING"]:
		heading.text = "%s WINGS   %d%%"%[mode,roundi(bike.transformation.progress*100)]
		condition.text = "Keep the wing space clear"
		controls.text = "W/S  Drive · A/D  Steer · Space  Brake"
	elif mode=="AIRCRAFT":
		if flying:
			heading.text += "   /   %.0f m AGL"%bike.flight.altitude
			condition.text = "LOW AIRSPEED · Hold W to recover" if slow else "IN FLIGHT · Land before folding or dismounting"
			controls.text = "W  Accelerate · S  Slow · Space  Climb · Ctrl  Descend · A/D  Turn"
		else:
			condition.text = "READY FOR TAKEOFF · Hold Space" if bike.speed>=12 else "Hold W · Reach 44 km/h, then Space to lift off"
			controls.text = "A/D  Steer · S  Slow · T  Fold below 29 km/h · E  Dismount when stopped"
	else:
		condition.text = "CART ATTACHED · %d / 160 kg cargo"%bike.tow_cart.inventory.mass() if bike.cart_attached and bike.tow_cart else ("REVERSING" if bike.speed<-0.1 else "GROUND DRIVE")
		controls.text = "W/S  Drive · A/D  Steer · Space  Brake · C  Hitch · T  Wings · E  Dismount"
