extends SceneTree

const RIG_PATH: String = "res://scenes/camera/exploration_camera_rig.tscn"
const ROOM_PATH: String = "res://scenes/worlds/movement_test/movement_test.tscn"

var _checks: int = 0
var _failures: int = 0
var _rig: Node3D
var _camera: Camera3D
var _target: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not ResourceLoader.exists(RIG_PATH):
		_expect(false, "OUUT-6 must provide a reusable camera scene.")
		quit(1)
		return
	create_timer(25.0).timeout.connect(func() -> void: push_error("Camera tests timed out."); quit(1))
	var world: Node3D = Node3D.new()
	root.add_child(world)
	world.transform = Transform3D(Basis(Vector3.UP, 0.7).scaled(Vector3(2, 2, 2)), Vector3(5, 0, -3))
	_target = Node3D.new()
	world.add_child(_target)
	_target.global_position = Vector3(2, 0, 3)
	_rig = (load(RIG_PATH) as PackedScene).instantiate() as Node3D
	_rig.set("target", _target)
	world.add_child(_rig)
	_camera = _rig.get_node("Camera3D") as Camera3D
	await _tick(3)
	_expect(_camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Camera must use perspective.")
	_expect(_camera.current, "Reusable camera must activate in its viewport.")
	_expect(_camera.global_basis.get_scale().is_equal_approx(Vector3.ONE), "Composing parent scale must not distort camera.")
	await _check_follow()
	await _check_rotation()
	await _check_zoom()
	await _check_input_gates()
	_target.queue_free()
	await _tick(2)
	_rig.call("snap_to_target")
	_expect(_camera.global_position.is_finite(), "Freed target must not corrupt camera transform.")
	_rig.set("target", null)
	await _tick(2)
	_target = Node3D.new()
	world.add_child(_target)
	_target.global_position = Vector3(-10, 2, 8)
	_rig.set("target", _target)
	_rig.call("snap_to_target")
	var offset: Vector3 = _rig.get("target_offset")
	_expect(_rig.global_position.is_equal_approx(_target.global_position + offset), "Cleared or freed targets must be safely replaceable.")
	world.queue_free()
	await _tick(2)
	await _check_room_movement()
	if _failures == 0:
		print("EXPLORATION_CAMERA_TEST_OK (%d checks)" % _checks)
	else:
		push_error("Exploration camera: %d of %d checks failed." % [_failures, _checks])
	quit(1 if _failures > 0 else 0)


func _check_follow() -> void:
	var offset: Vector3 = _rig.get("target_offset")
	_expect(_rig.global_position.is_equal_approx(_target.global_position + offset), "Initial camera anchor must snap to target plus framing offset.")
	var heading: float = _camera.global_rotation.y
	var before: Vector3 = _rig.global_position
	_target.global_position += Vector3(3, 0, 0)
	_target.rotation.y += 1.0
	await _tick()
	_expect(_rig.global_position.x > before.x and _rig.global_position.x < _target.global_position.x + offset.x, "Follow must move smoothly without instantly snapping.")
	await create_timer(0.7).timeout
	_expect(_rig.global_position.distance_to(_target.global_position + offset) < 0.05, "Follow must converge to target framing.")
	_expect(absf(angle_difference(heading, _camera.global_rotation.y)) < 0.001, "Target facing must not rotate camera.")
	_target.global_position += Vector3(20, 0, 5)
	_rig.call("snap_to_target")
	_expect(_rig.global_position.is_equal_approx(_target.global_position + offset), "Teleport reset must snap immediately.")
	_rig.set("target_offset", Vector3(0, 1.5, 0))
	_rig.call("snap_to_target")
	_expect(_rig.global_position.is_equal_approx(_target.global_position + Vector3(0, 1.5, 0)), "Framing offset must be tunable.")


func _check_rotation() -> void:
	for action: StringName in [&"camera_rotate_left", &"camera_rotate_right", &"camera_zoom_in", &"camera_zoom_out"]:
		_expect(InputMap.has_action(action), "Camera InputMap action %s must exist." % action)
	_rig.call("set_heading", 0.0, true)
	_key(KEY_E, true)
	await _tick(2)
	_expect(_near(_rig.call("get_target_heading"), 45.0), "E must request exactly one 45 degree rotation.")
	var yaw: float = rad_to_deg(_camera.global_rotation.y)
	_expect(yaw > 0.0 and yaw < 45.0, "Rotation must visibly interpolate toward requested heading (got %f)." % yaw)
	_key(KEY_E, true, true)
	await _tick()
	_expect(_near(_rig.call("get_target_heading"), 45.0), "Key repeat must not add rotation steps.")
	_key(KEY_E, false)
	_key(KEY_Q, true)
	_key(KEY_Q, false)
	await _tick()
	_expect(_near(_rig.call("get_target_heading"), 0.0), "Q must reverse a single E step.")
	_rig.call("set_heading", 315.0, true)
	_key(KEY_E, true)
	_key(KEY_E, false)
	await _tick()
	_expect(_near(_rig.call("get_target_heading"), 0.0), "Rotation must wrap 315 to 0 degrees.")
	var turned: float = angle_difference(deg_to_rad(315), _camera.global_rotation.y)
	_expect(turned > 0.0 and turned < PI / 4.0, "Wrap transition must take shortest forward arc.")
	await create_timer(0.7).timeout
	_expect(absf(angle_difference(0.0, _camera.global_rotation.y)) < 0.001, "Rotation must converge to requested heading.")
	for index: int in range(8):
		_key(KEY_Q, true)
		_key(KEY_Q, false)
		await _tick()
	_expect(_near(_rig.call("get_target_heading"), 0.0), "Eight left steps must complete a full orbit.")
	_rig.call("set_heading", 0.0, true)
	_key(KEY_Q, true)
	_key(KEY_Q, false)
	await _tick(2)
	_expect(_near(_rig.call("get_target_heading"), 315.0), "Left rotation must wrap 0 to 315 degrees.")
	turned = angle_difference(0.0, _camera.global_rotation.y)
	_expect(turned < 0.0 and turned > -PI / 4.0, "Reverse wrap must take shortest backward arc.")


func _check_zoom() -> void:
	var minimum: float = _rig.get("min_distance")
	var maximum: float = _rig.get("max_distance")
	_rig.call("set_distance", maximum, true)
	var far_pitch: float = -rad_to_deg(_camera.global_rotation.x)
	_wheel(MOUSE_BUTTON_WHEEL_UP)
	await _tick()
	var requested: float = _rig.call("get_target_distance")
	var rendered: float = _camera.global_position.distance_to(_rig.global_position)
	_expect(requested < maximum, "Wheel up must zoom toward the player.")
	_expect(rendered < maximum and rendered > requested, "Zoom must interpolate rather than snap.")
	for index: int in range(40):
		_wheel(MOUSE_BUTTON_WHEEL_UP)
	await _tick()
	_expect(_near(_rig.call("get_target_distance"), minimum), "Zoom in must clamp to minimum.")
	_rig.call("set_distance", minimum, true)
	var near_pitch: float = -rad_to_deg(_camera.global_rotation.x)
	_expect(far_pitch > near_pitch, "Zooming out must tilt farther downward.")
	_expect(_near(near_pitch, _rig.get("min_pitch_degrees")), "Close zoom must use configured minimum pitch.")
	_expect(_near(far_pitch, _rig.get("max_pitch_degrees")), "Far zoom must use configured maximum pitch.")
	for index: int in range(40):
		_wheel(MOUSE_BUTTON_WHEEL_DOWN)
	await _tick()
	_expect(_near(_rig.call("get_target_distance"), maximum), "Zoom out must clamp to maximum.")
	_wheel(MOUSE_BUTTON_WHEEL_UP)
	await _tick()
	_expect(_rig.call("get_target_distance") < maximum, "Zoom must reverse immediately after reaching a limit.")
	_rig.call("set_distance", -100.0, true)
	_expect(_near(_camera.global_position.distance_to(_rig.global_position), minimum), "Programmatic zoom must respect minimum.")


func _check_input_gates() -> void:
	_rig.call("set_heading", 0.0, true)
	_rig.call("set_distance", 20.0, true)
	_rig.call("set_controls_enabled", false)
	_key(KEY_E, true)
	_key(KEY_E, false)
	_wheel(MOUSE_BUTTON_WHEEL_UP)
	await _tick()
	_expect(not _rig.call("is_controls_enabled"), "Cutscene control gate must report disabled.")
	_expect(_near(_rig.call("get_target_heading"), 0.0) and _near(_rig.call("get_target_distance"), 20.0), "Disabled camera must ignore rotate and zoom input.")
	_rig.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_rig.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_expect(not _rig.call("is_controls_enabled"), "Focus return must not clear cutscene camera lock.")
	_rig.call("set_controls_enabled", true)
	_rig.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_key(KEY_E, true)
	_key(KEY_E, false)
	await _tick()
	_expect(_near(_rig.call("get_target_heading"), 0.0), "Unfocused window must ignore camera controls.")
	_rig.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	var entry: LineEdit = LineEdit.new()
	root.add_child(entry)
	entry.grab_focus()
	await _tick()
	_key(KEY_E, true)
	_key(KEY_E, false)
	_wheel(MOUSE_BUTTON_WHEEL_DOWN)
	await _tick()
	_expect(_near(_rig.call("get_target_heading"), 0.0) and _near(_rig.call("get_target_distance"), 20.0), "Focused text entry must block camera keys and wheel.")
	entry.release_focus()
	entry.queue_free()
	var multiline: TextEdit = TextEdit.new()
	root.add_child(multiline)
	multiline.grab_focus()
	await _tick()
	_key(KEY_E, true)
	_key(KEY_E, false)
	_wheel(MOUSE_BUTTON_WHEEL_DOWN)
	await _tick()
	_expect(_near(_rig.call("get_target_heading"), 0.0) and _near(_rig.call("get_target_distance"), 20.0), "Focused multiline text must block camera keys and wheel.")
	multiline.release_focus()
	multiline.queue_free()
	var panel: Control = Control.new()
	panel.size = Vector2(500, 500)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_force_pass_scroll_events = false
	panel.gui_input.connect(func(_event: InputEvent) -> void: panel.accept_event())
	root.add_child(panel)
	await _tick(2)
	_wheel(MOUSE_BUTTON_WHEEL_DOWN)
	await _tick()
	_expect(_near(_rig.call("get_target_distance"), 20.0), "GUI-consumed scroll must not zoom world camera.")
	panel.queue_free()
	var menu: Button = Button.new()
	root.add_child(menu)
	menu.grab_focus()
	await _tick()
	_key(KEY_E, true)
	_key(KEY_E, false)
	_wheel(MOUSE_BUTTON_WHEEL_UP)
	await _tick()
	_expect(_near(_rig.call("get_target_heading"), 0.0) and _near(_rig.call("get_target_distance"), 20.0), "Focused menu button must block camera input.")
	menu.release_focus()
	menu.queue_free()
	_key(KEY_E, true)
	_key(KEY_E, false)
	await _tick()
	_expect(_near(_rig.call("get_target_heading"), 45.0), "Camera controls must resume when menu releases focus.")


func _check_room_movement() -> void:
	var room: Node3D = (load(ROOM_PATH) as PackedScene).instantiate() as Node3D
	root.add_child(room)
	var player: CharacterBody3D = room.get_node("Player") as CharacterBody3D
	var rig: Node3D = room.get_node("CameraRig") as Node3D
	await _tick(4)
	rig.call("set_heading", 0.0, true)
	_key(KEY_E, true)
	_key(KEY_E, false)
	Input.action_press(&"move_right")
	await _tick()
	var requested_basis: Basis = rig.call("get_movement_basis")
	var motion: Vector3 = Vector3(player.velocity.x, 0, player.velocity.z).normalized()
	_expect(motion.dot(requested_basis.x) > 0.999, "Movement must use requested heading during rotation.")
	var visible_right: Vector3 = (rig.get_node("Camera3D") as Camera3D).global_basis.x
	_expect(motion.dot(visible_right) < 0.999, "Movement test must actually exercise an unfinished visible rotation.")
	Input.action_press(&"move_up")
	Input.action_press(&"run")
	await _tick()
	_expect(_near(Vector2(player.velocity.x, player.velocity.z).length(), 6.0), "Running diagonally during rotation must stay at 6 m/s.")
	for action: StringName in [&"move_right", &"move_up", &"run"]:
		Input.action_release(action)
	player.position = Vector3(-3, 0.05, 7)
	player.reset_physics_interpolation()
	_key(KEY_R, true)
	_key(KEY_R, false)
	await _tick(2)
	var offset: Vector3 = rig.get("target_offset")
	_expect(rig.global_position.distance_to(player.global_position + offset) < 0.1, "R must snap the framing anchor to reset player.")
	room.queue_free()
	await _tick(2)


func _key(key: int, pressed: bool, echo: bool = false) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)


func _wheel(button: MouseButton) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = root.get_final_transform() * Vector2(100, 100)
	Input.parse_input_event(event)


func _tick(count: int = 1) -> void:
	for index: int in range(count):
		await physics_frame
		await process_frame


func _near(actual: float, expected: float) -> bool:
	return absf(actual - expected) < 0.02


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
