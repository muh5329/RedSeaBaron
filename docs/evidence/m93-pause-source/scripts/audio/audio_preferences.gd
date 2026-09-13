class_name AudioPreferences
extends RefCounted
signal changed
var path: String = "user://audio_settings.cfg"
var level: float = 1.0
var muted: bool = false

func apply() -> void:
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(level,0.0001)))
	AudioServer.set_bus_mute(0,muted or level<=0)
	changed.emit()

func set_level(value: float) -> void:
	if not is_finite(value): return
	level = clampf(value,0,1)
	apply()

func set_muted(value: bool) -> void:
	muted = value
	apply()

func store() -> bool:
	var config := ConfigFile.new()
	config.set_value("audio","volume",level)
	config.set_value("audio","muted",muted)
	if config.save(path+".tmp")!=OK: return false
	return DirAccess.rename_absolute(path+".tmp",path)==OK

func load_settings() -> bool:
	if not FileAccess.file_exists(path): return false
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null: return false
	var size := file.get_length()
	file.close()
	if size>4096: return false
	var config := ConfigFile.new()
	if config.load(path)!=OK: return false
	var saved_level: Variant = config.get_value("audio","volume",null)
	var saved_mute: Variant = config.get_value("audio","muted",null)
	if not (saved_level is float or saved_level is int) or not saved_mute is bool: return false
	if not is_finite(float(saved_level)) or float(saved_level)<0 or float(saved_level)>1: return false
	level = float(saved_level)
	muted = saved_mute
	apply()
	return true
