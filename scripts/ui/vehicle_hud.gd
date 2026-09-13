class_name VehicleHUD
extends VBoxContainer
## Presentation of controller state; flight and seat systems own the rules.
const CREAM := Color("e9dfc6")
const GOLD := Color("e4b571")
const MUTED := Color("a9bdb3")
const WARNING := Color("edaa76")
var heading: Label
var instruments: Label
var navigation_target: Variant = null
var condition: Label
var controls: Label
var speed_bar: ProgressBar
var normal_fill: StyleBoxFlat
var warning_fill: StyleBoxFlat
var warning_active: bool = false

func _ready() -> void:
	add_theme_constant_override("separation",5)
	heading = _line(18,CREAM)
	instruments = _line(12,MUTED)
	instruments.visible = false
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

func course_to(target: Vector3, bike: BikeController) -> Dictionary:
	var offset := Vector2(target.x-bike.position.x,target.z-bike.position.z)
	var bearing := wrapf(rad_to_deg(atan2(offset.x,-offset.y)),0,360)
	var heading_degrees := wrapf(rad_to_deg(-bike.rotation.y),0,360)
	return {"bearing":bearing,"heading":heading_degrees,"turn":wrapf(bearing-heading_degrees,-180,180),"distance":offset.length()}

func course_label(target: Vector3, bike: BikeController) -> String:
	var course := course_to(target,bike)
	if course.distance<12: return "TARGET NEARBY · %.0f m"%course.distance
	var direction := "ON COURSE" if absf(course.turn)<3 else "%s %.0f°"%["RIGHT" if course.turn>0 else "LEFT",absf(course.turn)]
	var distance := "%.1f km"%(course.distance/1000) if course.distance>=1000 else "%.0f m"%course.distance
	return "COURSE %03d° · %s · %s"%[roundi(course.bearing)%360,direction,distance]

func refresh(seat: VehicleSeat) -> void:
	var bike := seat.bike
	var mode := bike.transformation.mode
	var flying := bike.flight.airborne
	instruments.visible = seat.mounted and flying
	var slow := (flying and bike.speed<12) or bike.transformation.transition_blocked
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
		condition.text = "WINGS BLOCKED · Reverse into open ground to continue" if bike.transformation.transition_blocked else "Keep the wing space clear"
		controls.text = "W/S  Drive · A/D  Steer · Space  Brake"
	elif mode=="AIRCRAFT":
		if flying:
			heading.text += "   /   %.0f m AGL"%bike.flight.altitude
			instruments.text = "HDG %03d° · VERTICAL %s%.1f m/s"%[roundi(wrapf(rad_to_deg(-bike.rotation.y),0,360))%360,"+" if bike.velocity.y>=0 else "",bike.velocity.y]
			condition.text = "LOW AIRSPEED · Hold Space to recover" if slow else (course_label(navigation_target,bike) if navigation_target!=null else "IN FLIGHT · Land before folding or dismounting")
			controls.text = "S  Pull up · W  Dive · Space  Boost · Shift  Brake · A/D  Turn"
		else:
			condition.text = "READY FOR TAKEOFF · Hold S / back" if bike.speed>=12 else "W / Space · Reach 44 km/h, then S to lift off"
			controls.text = "W  Drive · S  Pull up · Shift  Brake · T  Fold · E  Dismount"
	else:
		condition.text = "CART ATTACHED · %d / 160 kg cargo"%bike.tow_cart.inventory.mass() if bike.cart_attached and bike.tow_cart else ("REVERSING" if bike.speed<-0.1 else "GROUND DRIVE")
		controls.text = "W/S  Drive · A/D  Steer · Space  Brake · C  Hitch · T  Wings · E  Dismount"
