extends SceneTree

const TEST_SETTINGS_PATH: String = "user://ouut_1_title_screen_test.cfg"

var _failures: int = 0
var _start_requests: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/app/main.tscn") as PackedScene
	var main: Control = main_scene.instantiate() as Control
	var title: Control = main.get_node_or_null("TitleScreen") as Control
	if title == null:
		_expect(false, "Application must launch the title screen instead of the placeholder label.")
		main.free()
		quit(1)
		return

	# Use an isolated configuration file; never overwrite the player's preferences.
	DirAccess.remove_absolute(TEST_SETTINGS_PATH)
	var panel: Control = title.get_node("SettingsPanel") as Control
	panel.set("settings_path", TEST_SETTINGS_PATH)
	var original_volume: float = AudioServer.get_bus_volume_db(0)
	var original_mute: bool = AudioServer.is_bus_mute(0)
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var start: Button = title.get_node("%StartButton") as Button
	var settings: Button = title.get_node("%SettingsButton") as Button
	var quit_button: Button = title.get_node("%QuitButton") as Button
	if "--quit-check" in OS.get_cmdline_user_args():
		print("TITLE_SCREEN_QUIT_REQUESTED")
		quit_button.pressed.emit()
		await process_frame
		_expect(false, "Quit must exit the desktop game.")
		quit(1)
		return

	_expect(start.text == "Start Game", "Start Game must have the story's label.")
	_expect(settings.text == "Settings", "Settings must have the story's label.")
	_expect(quit_button.text == "Quit", "Quit must have the story's label.")
	_expect(root.gui_get_focus_owner() == start, "Start Game must receive initial keyboard focus.")
	_expect(start.get_node("LeftOrnament").visible, "Selected button must show the gold ornaments.")
	_expect(not settings.get_node("LeftOrnament").visible, "Unselected buttons must hide ornaments.")

	_send_key(KEY_DOWN)
	await process_frame
	_expect(root.gui_get_focus_owner() == settings, "Down arrow must move from Start Game to Settings.")
	_expect(settings.get_node("LeftOrnament").visible, "Gold ornaments must follow keyboard focus.")
	_expect(not start.get_node("LeftOrnament").visible, "Previous selection must lose its ornaments.")
	start.mouse_entered.emit()
	await process_frame
	_expect(root.gui_get_focus_owner() == start, "Mouse hover must select the hovered button.")

	start.pressed.emit()
	await process_frame
	var notice: AcceptDialog = title.get_node("StartNotice") as AcceptDialog
	_expect(notice.visible, "Start Game must show the approved intro-coming-soon notice.")
	_expect(start.disabled and settings.disabled, "Intro notice must block the underlying menu.")
	_expect(notice.dialog_close_on_escape, "Intro notice must enable the engine's Escape handling.")
	notice.get_ok_button().pressed.emit()
	await process_frame
	_expect(not notice.visible, "Back must close the intro notice.")
	_expect(root.gui_get_focus_owner() == start, "Closing the notice must restore Start Game focus.")
	_expect(not settings.disabled, "Closing the notice must enable the menu again.")

	# A future intro listener must replace the temporary notice.
	title.connect("start_requested", _record_start_request)
	start.pressed.emit()
	_expect(_start_requests == 1, "Start must notify a connected intro listener.")
	_expect(not notice.visible, "The temporary notice must not obscure a connected intro.")
	title.disconnect("start_requested", _record_start_request)

	_send_mouse_click(settings.get_global_rect().get_center())
	await process_frame
	_expect(panel.visible, "Settings must open its panel.")
	_expect(start.disabled and settings.disabled and quit_button.disabled, "Settings must disable all menu buttons.")
	_expect(panel.is_ancestor_of(root.gui_get_focus_owner()), "Focus must remain inside the settings panel.")
	_send_key(KEY_TAB)
	await process_frame
	_expect(panel.is_ancestor_of(root.gui_get_focus_owner()), "Tab must not escape into the title buttons.")
	var volume: HSlider = panel.get_node("%MasterVolume") as HSlider
	volume.value = 0.0
	_expect(AudioServer.is_bus_mute(0), "Zero volume must mute the master audio bus.")
	var back: Button = panel.get_node("%BackButton") as Button
	back.pressed.emit()
	await process_frame
	_expect(not panel.visible, "Back must close Settings.")
	_expect(root.gui_get_focus_owner() == settings, "Back must restore Settings-button focus.")
	var saved: ConfigFile = ConfigFile.new()
	_expect(saved.load(TEST_SETTINGS_PATH) == OK, "Closing Settings must persist the preferences.")
	_expect(is_equal_approx(float(saved.get_value("audio", "master_volume", -1.0)), 0.0), "Saved volume must match the slider.")

	settings.pressed.emit()
	await process_frame
	_send_key(KEY_ESCAPE)
	await process_frame
	_expect(not panel.visible, "Escape must close Settings.")
	_expect(root.gui_get_focus_owner() == settings, "Escape must restore menu focus.")

	var settings_scene: PackedScene = load("res://scenes/ui/settings/settings_panel.tscn") as PackedScene
	var restored: Control = settings_scene.instantiate() as Control
	restored.set("settings_path", TEST_SETTINGS_PATH)
	root.add_child(restored)
	_expect(root.gui_get_focus_owner() == restored.get_node("%MasterVolume"), "Standalone Settings must receive keyboard focus.")
	_expect(is_equal_approx((restored.get_node("%MasterVolume") as HSlider).value, 0.0), "A new settings instance must restore saved volume.")
	restored.queue_free()
	await process_frame

	for window_size: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(800, 600), Vector2i(1600, 720)]:
		root.size = window_size
		await process_frame
		await process_frame
		var artwork: Control = title.get_node("Aspect/Artwork") as Control
		_expect(absf(artwork.size.x / artwork.size.y - 16.0 / 9.0) < 0.01, "Artwork must keep its 16:9 proportions at " + str(window_size))
		_expect(artwork.get_global_rect().encloses(start.get_global_rect()), "Start Game must remain within the artwork after resize.")
		_expect(artwork.get_global_rect().encloses(quit_button.get_global_rect()), "Quit must remain within the artwork after resize.")

	root.size = Vector2i(1920, 1080)
	await process_frame
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		start.grab_focus()
		await _capture("title_screen")
		settings.pressed.emit()
		await process_frame
		await _capture("title_settings")
		back.pressed.emit()
		start.grab_focus()
		start.pressed.emit()
		await process_frame
		await _capture("title_start_notice")
		notice.hide()

	AudioServer.set_bus_volume_db(0, original_volume)
	AudioServer.set_bus_mute(0, original_mute)
	DirAccess.remove_absolute(TEST_SETTINGS_PATH)
	if _failures == 0:
		print("TITLE_SCREEN_TEST_OK")
	quit(0 if _failures == 0 else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)


func _send_key(key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = false
	Input.parse_input_event(event)


func _send_mouse_click(position: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		# Input.parse_input_event expects window pixels, including stretch/letterbox.
		event.position = root.get_final_transform() * position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)


func _record_start_request() -> void:
	_start_requests += 1


func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var capture: Image = root.get_texture().get_image()
	_expect(capture.save_png("res://docs/superpowers/assets/" + filename + ".png") == OK, "Rendered screenshot must save successfully.")
