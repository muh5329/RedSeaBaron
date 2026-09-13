class_name AudioSettingsPanel
extends HBoxContainer
signal write_failed
var preferences: AudioPreferences
var mute_button: Button
var volume: HSlider
var readout: Label
var save_timer: Timer

func _ready() -> void:
	name = "AudioSettings"
	custom_minimum_size.y = 44
	add_theme_constant_override("separation",10)
	mute_button = Button.new()
	mute_button.custom_minimum_size.x = 104
	mute_button.toggle_mode = true
	mute_button.tooltip_text = "Mute all game sound"
	add_child(mute_button)
	volume = HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 5
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	volume.custom_minimum_size.x = 140
	volume.tooltip_text = "Master volume"
	add_child(volume)
	readout = Label.new()
	readout.custom_minimum_size.x = 48
	readout.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(readout)
	save_timer = Timer.new()
	save_timer.one_shot = true
	save_timer.wait_time = 0.3
	add_child(save_timer)
	save_timer.timeout.connect(func():
		if not preferences.store(): write_failed.emit()
	)
	mute_button.pressed.connect(func():
		preferences.set_muted(not preferences.muted)
		save_timer.start()
	)
	volume.value_changed.connect(func(value):
		preferences.set_level(value/100.0)
		save_timer.start()
	)
	preferences.changed.connect(refresh)
	refresh()

func refresh() -> void:
	mute_button.set_pressed_no_signal(preferences.muted)
	mute_button.text = "Muted" if preferences.muted else "Sound on"
	volume.set_value_no_signal(preferences.level*100)
	readout.text = "%d%%"%roundi(preferences.level*100)
