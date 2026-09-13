class_name IncomingDamageFeedback
extends Control
## A short peripheral cue; it never consumes input or covers the aiming center.
const DURATION: float = 0.55
var health: HealthComponent
var active: bool = false
var remaining: float = 0
var strength: float = 0
var peak: float = 0
var pulses: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	health.damaged.connect(flash)
	health.restored.connect(clear)

func set_active(value: bool) -> void:
	active = value
	if not active: clear()

func flash(amount: float) -> void:
	if not active or amount<=0: return
	pulses += 1
	remaining = DURATION
	peak = clampf(0.20+amount/maxf(1,health.maximum)*0.6,0.20,0.55)
	strength = peak
	visible = true
	queue_redraw()

func clear() -> void:
	remaining = 0
	strength = 0
	visible = false
	queue_redraw()

func _process(delta: float) -> void:
	if remaining<=0: return
	remaining = maxf(0,remaining-delta)
	strength = peak*pow(remaining/DURATION,2)
	visible = remaining>0
	queue_redraw()

func _draw() -> void:
	for layer in range(6):
		var inset := layer*4.0
		var tint := Color(0.76,0.15,0.10,strength*pow(1-layer/6.0,2))
		draw_rect(Rect2(inset,inset,size.x-inset*2,4),tint)
		draw_rect(Rect2(inset,size.y-inset-4,size.x-inset*2,4),tint)
		draw_rect(Rect2(inset,inset+4,4,size.y-inset*2-8),tint)
		draw_rect(Rect2(size.x-inset-4,inset+4,4,size.y-inset*2-8),tint)
