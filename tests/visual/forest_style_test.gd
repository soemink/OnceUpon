extends SceneTree

const SCENE_PATH: String = "res://scenes/worlds/movement_test/movement_test.tscn"
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not ResourceLoader.exists(SCENE_PATH):
		_expect(false, "The forest vignette must exist as a standalone scene.")
		quit(1)
		return
	create_timer(15.0).timeout.connect(func() -> void: push_error("Forest tests timed out."); quit(1))
	var world: Node3D = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	var player: CharacterBody3D = world.get_node("Player") as CharacterBody3D
	var rig: Node3D = world.get_node("CameraRig") as Node3D
	await _tick(8)
	_expect(player.is_on_floor(), "Forest floor must support the player.")
	_expect(player.get("movement_reference") == rig, "Forest player must use the reusable camera heading.")
	_expect((rig.get_node("Camera3D") as Camera3D).current, "Forest camera must be current.")
	if not world.has_node("Scenery/Tree0"):
		_expect(false, "The movement room must contain illustrated forest props.")
		world.queue_free()
		await process_frame
		quit(1)
		return
	var tree: StaticBody3D = world.get_node("Scenery/Tree0") as StaticBody3D
	_expect(tree.get_node("CollisionShape3D").shape is CylinderShape3D, "Illustrated tree must have a physical trunk.")
	var sprite: Sprite3D = tree.get_node("Illustration") as Sprite3D
	_expect(sprite.texture != null and sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y, "Tree art must be upright camera-facing cutouts.")
	_expect(sprite.texture.get_width() == 1024 and sprite.texture.get_height() == 1024, "Tree export must import at the power-of-two runtime limit.")
	var ground: MeshInstance3D = world.get_node("Scenery/IllustratedGround") as MeshInstance3D
	var ground_material: StandardMaterial3D = ground.material_override as StandardMaterial3D
	_expect(ground_material.albedo_texture.get_width() == 1024 and ground_material.albedo_texture.get_height() == 1024, "Ground export must import at the power-of-two runtime limit.")
	_expect(not (world.get_node("Grid") as Node3D).visible, "The blockout grid must not appear in the illustrated room.")
	for name: String in ["Floor", "North", "South", "East", "West", "LongWall", "CornerArm", "CornerStem"]:
		_expect(not (world.get_node(name + "/Mesh") as MeshInstance3D).visible, "The original %s block mesh must stay hidden." % name)
	var start: Vector3 = player.position
	Input.action_press(&"move_right")
	Input.action_press(&"run")
	await _tick(5)
	_expect(player.position.distance_to(start) > 0.25, "The clearing must allow movement.")
	_expect(absf(Vector2(player.velocity.x, player.velocity.z).length() - 6.0) < 0.02, "Forest running must preserve the 2x speed.")
	Input.action_release(&"move_right")
	Input.action_release(&"run")
	# Approach the first trunk from world -X using an identity movement heading.
	rig.call("set_heading", 0.0, true)
	player.position = tree.position + Vector3(-2, 0.1, 0)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	Input.action_press(&"move_right")
	await _tick(55)
	_expect(player.position.x < tree.position.x - 0.3, "Invisible tree collision must block walking through the trunk.")
	_expect(player.is_on_wall(), "Tree trunk must register as a wall.")
	Input.action_release(&"move_right")
	_key(KEY_R)
	await _tick(3)
	_expect(player.position.distance_to(start) < 0.1, "R must restore the forest spawn.")
	_expect(rig.global_position.distance_to(player.global_position + rig.get("target_offset")) < 0.1, "Forest reset must snap the camera.")
	_key(KEY_L)
	await _tick()
	_expect(not player.call("is_movement_enabled"), "L must toggle forest movement lock.")
	world.queue_free()
	await process_frame
	if _failures == 0:
		print("FOREST_STYLE_TEST_OK (%d checks)" % _checks)
	quit(0 if _failures == 0 else 1)


func _key(code: int) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	Input.parse_input_event(event)


func _tick(count: int = 1) -> void:
	for index: int in range(count):
		await physics_frame
		await process_frame


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
