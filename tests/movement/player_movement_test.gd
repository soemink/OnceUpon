extends SceneTree

const ROOM_PATH: String = "res://scenes/worlds/movement_test/movement_test.tscn"
const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down", &"run"]

var _failures: int = 0
var _checks: int = 0
var _room: Node3D
var _player: CharacterBody3D
var _camera: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not ResourceLoader.exists(ROOM_PATH):
		_expect(false, "OUUT-2 must provide a standalone movement test room.")
		quit(1)
		return
	var packed: PackedScene = load(ROOM_PATH) as PackedScene
	_room = packed.instantiate() as Node3D
	root.add_child(_room)
	current_scene = _room
	_player = _room.get_node("Player") as CharacterBody3D
	_camera = _room.get_node("CameraRig/Camera3D") as Camera3D
	var watchdog: SceneTreeTimer = create_timer(20.0)
	watchdog.timeout.connect(_timed_out)
	await _tick(5)
	_check_input_map()
	await _check_walking_and_running()
	await _check_locking_and_facing()
	await _check_physical_keyboard_and_room_controls()
	await _check_focus()
	await _check_collisions()
	await _check_camera()
	_release_inputs()
	_room.queue_free()
	await process_frame
	if _failures == 0:
		print("PLAYER_MOVEMENT_TEST_OK (%d checks)" % _checks)
	else:
		push_error("Player movement: %d of %d checks failed." % [_failures, _checks])
	quit(1 if _failures > 0 else 0)


func _check_input_map() -> void:
	var mappings: Dictionary = {
		&"move_left": [KEY_A, KEY_LEFT], &"move_right": [KEY_D, KEY_RIGHT],
		&"move_up": [KEY_W, KEY_UP], &"move_down": [KEY_S, KEY_DOWN], &"run": [KEY_SHIFT],
	}
	for action: StringName in mappings:
		_expect(InputMap.has_action(action), "Movement action %s must exist." % action)
		for key: int in mappings[action]:
			var found: bool = false
			for event: InputEvent in InputMap.action_get_events(action):
				if event is InputEventKey and event.physical_keycode == key:
					found = true
			_expect(found, "%s must bind physical key %s." % [action, key])


func _check_walking_and_running() -> void:
	await _reset(Vector3(0, 0.05, 5))
	var start: Vector3 = _player.position
	Input.action_press(&"move_right")
	await _tick()
	_expect(_near(_speed(), 3.0), "Walking must reach 3 m/s on the first tick.")
	var right: Vector3 = _camera.global_basis.x
	right.y = 0
	_expect(_horizontal_velocity().normalized().dot(right.normalized()) > 0.999, "Right must follow the camera's ground-plane right.")
	await _tick(6)
	_expect(_player.position.distance_to(start) > 0.2, "Walk input must physically move the player.")
	Input.action_press(&"move_up")
	await _tick()
	_expect(_near(_speed(), 3.0), "Diagonal walking must not be faster.")
	Input.action_press(&"run")
	await _tick()
	_expect(_near(_speed(), 6.0), "Running must reach 6.0 m/s immediately.")
	Input.action_release(&"move_up")
	await _tick()
	_expect(_near(_speed(), 6.0), "Cardinal and diagonal running must have equal speed.")
	Input.action_release(&"run")
	await _tick()
	_expect(_near(_speed(), 3.0), "Releasing Shift must return immediately to walking.")
	_release_inputs()
	await _tick()
	_expect(_near(_speed(), 0.0), "Releasing directions must stop immediately.")
	Input.action_press(&"run")
	await _tick()
	_expect(_near(_speed(), 0.0), "Shift alone must not move the player.")
	Input.action_press(&"move_right")
	Input.action_press(&"move_left")
	await _tick()
	_expect(_near(_speed(), 0.0), "Opposing direction inputs must cancel.")
	_release_inputs()
	Input.action_press(&"move_up")
	await _tick()
	var forward: Vector3 = -_camera.global_basis.z
	forward.y = 0
	_expect(_horizontal_velocity().normalized().dot(forward.normalized()) > 0.999, "Up must follow the camera's ground-plane forward.")
	_release_inputs()
	_player.set("walk_speed", 2.0)
	Input.action_press(&"move_down")
	await _tick()
	_expect(_near(_speed(), 2.0), "Walking speed must be tunable.")
	Input.action_press(&"run")
	await _tick()
	_expect(_near(_speed(), 4.0), "Running must remain exactly twice the tuned walking speed.")
	_player.set("walk_speed", 0.0)
	await _tick()
	_expect(_near(_speed(), 0.0), "Zero walking speed must also stop running.")
	_player.set("walk_speed", 3.0)
	_release_inputs()


func _check_locking_and_facing() -> void:
	await _reset(Vector3(0, 0.05, 5))
	Input.action_press(&"move_left")
	await _tick(2)
	var sprite: AnimatedSprite3D = _player.get_node("Visual") as AnimatedSprite3D
	_expect(sprite.animation == &"walk_left", "Leftward motion must select the left walk animation.")
	Input.action_press(&"run")
	await _tick()
	_expect(sprite.animation == &"run_left", "Running must select its directional animation.")
	_player.call("set_movement_enabled", false)
	_expect(_near(_speed(), 0.0), "Locking movement must immediately clear horizontal velocity.")
	var stopped: Vector3 = _player.position
	await _tick(8)
	_expect(Vector2(_player.position.x, _player.position.z).distance_to(Vector2(stopped.x, stopped.z)) < 0.001, "Held inputs must not move a locked player.")
	_expect(sprite.animation == &"idle_left", "A stopped player must retain its last facing.")
	_player.call("set_movement_enabled", true)
	await _tick()
	_expect(_near(_speed(), 6.0), "Unlocking must restore held keyboard controls.")
	_release_inputs()
	await _tick()
	_expect(sprite.animation == &"idle_left", "Releasing controls must preserve facing.")
	for direction: String in ["up", "down", "right", "left"]:
		Input.action_press(StringName("move_" + direction))
		await _tick()
		_expect(sprite.animation == StringName("walk_" + direction), "Each movement direction must have a matching sprite facing.")
		_release_inputs()
	for direction: String in ["up", "down", "right", "left"]:
		for mode: String in ["idle", "walk", "run"]:
			_expect(sprite.sprite_frames.has_animation(StringName(mode + "_" + direction)), "Placeholder animation %s_%s must exist." % [mode, direction])


func _check_physical_keyboard_and_room_controls() -> void:
	await _reset(Vector3(0, 0.05, 5))
	for key: int in [KEY_A, KEY_D, KEY_W, KEY_S, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		_send_key(key, true)
		await _tick()
		_expect(_near(_speed(), 3.0), "Physical key %s must drive walking through InputMap." % key)
		_send_key(key, false)
		await _tick()
		_expect(_near(_speed(), 0.0), "Releasing physical key %s must stop walking." % key)
	_send_key(KEY_D, true)
	_send_key(KEY_SHIFT, true)
	await _tick(3)
	_expect(_near(_speed(), 6.0), "Physical Shift must switch physical movement input to running.")
	_send_key(KEY_L, true)
	_send_key(KEY_L, false)
	await _tick()
	_expect(not _player.call("is_movement_enabled") and _near(_speed(), 0.0), "L must lock movement through the room's input handler.")
	_send_key(KEY_L, true)
	_send_key(KEY_L, false)
	await _tick()
	_expect(_player.call("is_movement_enabled") and _near(_speed(), 6.0), "A second L must unlock movement.")
	_send_key(KEY_D, false)
	_send_key(KEY_SHIFT, false)
	await _tick()
	_player.position = Vector3(-3, 0.05, 7)
	_player.reset_physics_interpolation()
	_send_key(KEY_R, true)
	_send_key(KEY_R, false)
	await _tick(2)
	_expect(_player.position.distance_to(Vector3(0, 0, 5)) < 0.1, "R must restore the room's spawn position.")
	_expect(_room.get_node("CameraRig").position.distance_to(_player.position + _room.get_node("CameraRig").get("target_offset")) < 0.1, "R must snap the following camera to the reset player.")


func _check_focus() -> void:
	Input.action_press(&"move_left")
	await _tick()
	_player.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(_near(_speed(), 0.0), "Losing application focus must stop movement immediately.")
	await _tick(3)
	_expect(_near(_speed(), 0.0), "Held input must be ignored while unfocused.")
	_player.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await _tick()
	_expect(_near(_speed(), 3.0), "Regaining focus must restore controls.")
	_player.call("set_movement_enabled", false)
	_player.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_player.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await _tick()
	_expect(_near(_speed(), 0.0) and not _player.call("is_movement_enabled"), "Focus changes must not remove an existing dialogue/menu lock.")
	_release_inputs()
	_player.call("set_movement_enabled", true)


func _send_key(key: int, pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)


func _check_collisions() -> void:
	# Identity camera basis makes right = world +X for deterministic wall checks.
	var rig: Node3D = _room.get_node("CameraRig") as Node3D
	var orientation: float = rig.call("get_target_heading")
	rig.call("set_heading", 0.0, true)
	await _reset(Vector3(0, 0.05, 0))
	Input.action_press(&"move_right")
	Input.action_press(&"run")
	await _tick(80)
	_expect(_player.position.x < 2.5, "Running must not pass through the central wall.")
	_expect(_player.is_on_wall(), "A blocked player must report a wall collision.")
	var before_slide: Vector3 = _player.position
	Input.action_press(&"move_down")
	await _tick(20)
	_expect(_player.position.z > before_slide.z + 0.5, "Diagonal input must slide along a wall.")
	_expect(_player.position.x < 2.5, "Wall sliding must retain collision blocking.")
	_release_inputs()
	Input.action_press(&"move_left")
	await _tick(12)
	_expect(_player.position.x < before_slide.x - 0.3, "The player must be able to turn away from a wall.")
	_release_inputs()
	await _reset(Vector3(9, 0.05, 9))
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	Input.action_press(&"run")
	await _tick(80)
	_expect(_player.position.x < 12 and _player.position.z < 12, "The perimeter corner must contain a running player.")
	var corner: Vector3 = _player.position
	_release_inputs()
	Input.action_press(&"move_left")
	Input.action_press(&"move_up")
	await _tick(15)
	_expect(_player.position.distance_to(corner) > 0.5, "The player must escape a corner when moving away.")
	_release_inputs()
	_expect(_player.is_on_floor(), "The character must remain grounded.")
	rig.call("set_heading", orientation, true)


func _check_camera() -> void:
	await _reset(Vector3(0, 0.05, 5))
	var rig: Node3D = _room.get_node("CameraRig") as Node3D
	var rotation_before: Vector3 = _camera.global_rotation
	var distance_before: float = _camera.global_position.distance_to(rig.global_position)
	var fov_before: float = _camera.fov
	var position_before: Vector3 = rig.position
	Input.action_press(&"move_left")
	await _tick(12)
	_release_inputs()
	await create_timer(0.25).timeout
	_expect(rig.position.distance_to(position_before) > 0.1, "The camera rig must follow player translation.")
	_expect(rig.position.distance_to(_player.position + rig.get("target_offset")) < 0.2, "Follow smoothing must converge toward the player.")
	_expect(_camera.global_rotation.is_equal_approx(rotation_before), "Following must preserve the isometric camera angle.")
	_expect(_near(_camera.global_position.distance_to(rig.global_position), distance_before), "Running and following must not change zoom.")
	_expect(is_equal_approx(_camera.fov, fov_before), "Following must preserve perspective field of view.")
	_expect(_camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "The test room must use a perspective camera.")


func _reset(at: Vector3) -> void:
	_release_inputs()
	_player.call("set_movement_enabled", true)
	_player.position = at
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	_room.get_node("CameraRig").call("snap_to_target")
	await _tick(8)


func _tick(count: int = 1) -> void:
	for index: int in range(count):
		await physics_frame
		await process_frame


func _release_inputs() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)


func _horizontal_velocity() -> Vector3:
	return Vector3(_player.velocity.x, 0, _player.velocity.z)


func _speed() -> float:
	return _horizontal_velocity().length()


func _near(actual: float, expected: float) -> bool:
	return absf(actual - expected) < 0.02


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)


func _timed_out() -> void:
	push_error("Movement tests exceeded 20 seconds.")
	quit(1)
