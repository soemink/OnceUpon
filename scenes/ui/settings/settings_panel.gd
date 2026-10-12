extends Control

signal closed

@export var settings_path: String = "user://settings.cfg"

@onready var _volume: HSlider = %MasterVolume
@onready var _volume_value: Label = %VolumeValue
@onready var _back_button: Button = %BackButton

var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	var load_error: Error = _config.load(settings_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Could not read audio settings; using the default volume.")
	var saved_volume: Variant = _config.get_value("audio", "master_volume", 100.0)
	if saved_volume is float or saved_volume is int:
		_volume.value = clampf(float(saved_volume), 0.0, 100.0)
	else:
		_volume.value = 100.0
	_volume.value_changed.connect(_apply_volume)
	_back_button.pressed.connect(_close)
	_volume.focus_next = _volume.get_path_to(_back_button)
	_volume.focus_previous = _volume.get_path_to(_back_button)
	_back_button.focus_next = _back_button.get_path_to(_volume)
	_back_button.focus_previous = _back_button.get_path_to(_volume)
	_apply_volume(_volume.value)
	set_process_unhandled_key_input(visible)
	if visible:
		_volume.grab_focus()


func open() -> void:
	show()
	set_process_unhandled_key_input(true)
	_volume.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _apply_volume(value: float) -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, is_zero_approx(value))
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(value / 100.0, 0.001)))
	_volume_value.text = "%d%%" % roundi(value)


func _close() -> void:
	_config.set_value("audio", "master_volume", _volume.value)
	if _config.save(settings_path) != OK:
		push_warning("Could not save audio settings.")
	hide()
	set_process_unhandled_key_input(false)
	closed.emit()
