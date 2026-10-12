extends Control

## Connect this signal when the intro is available. Standalone runs show a notice.
signal start_requested

@onready var _start_button: Button = %StartButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _settings_panel: Control = $SettingsPanel
@onready var _start_notice: AcceptDialog = $StartNotice

var _buttons: Array[Button] = []


func _ready() -> void:
	_buttons = [_start_button, _settings_button]
	# Browsers own their tabs; a desktop Quit action is not useful in web builds.
	_quit_button.visible = not OS.has_feature("web")
	if _quit_button.visible:
		_buttons.append(_quit_button)
	for index: int in _buttons.size():
		var button: Button = _buttons[index]
		var previous: Button = _buttons[posmod(index - 1, _buttons.size())]
		var next: Button = _buttons[(index + 1) % _buttons.size()]
		button.focus_neighbor_top = button.get_path_to(previous)
		button.focus_neighbor_bottom = button.get_path_to(next)
		button.focus_previous = button.get_path_to(previous)
		button.focus_next = button.get_path_to(next)
		button.focus_entered.connect(_select_button.bind(button))
		button.mouse_entered.connect(_focus_button.bind(button))
	_start_button.pressed.connect(_on_start_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_settings_panel.closed.connect(_on_settings_closed)
	_start_notice.visibility_changed.connect(_on_notice_visibility_changed)
	_start_notice.get_ok_button().text = "Back"
	_start_button.grab_focus()


func _focus_button(button: Button) -> void:
	if not button.disabled:
		button.grab_focus()


func _select_button(selected: Button) -> void:
	for button: Button in _buttons:
		var is_selected: bool = button == selected
		(button.get_node("LeftOrnament") as TextureRect).visible = is_selected
		(button.get_node("RightOrnament") as TextureRect).visible = is_selected


func _set_menu_enabled(enabled: bool) -> void:
	for button: Button in _buttons:
		button.disabled = not enabled


func _on_start_pressed() -> void:
	if start_requested.get_connections().is_empty():
		_set_menu_enabled(false)
		_start_notice.popup_centered(Vector2i(420, 160))
		_start_notice.get_ok_button().grab_focus()
	else:
		start_requested.emit()


func _on_notice_visibility_changed() -> void:
	if not _start_notice.visible:
		_set_menu_enabled(true)
		_start_button.grab_focus()


func _on_settings_pressed() -> void:
	_set_menu_enabled(false)
	_settings_panel.open()


func _on_settings_closed() -> void:
	_set_menu_enabled(true)
	_settings_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
