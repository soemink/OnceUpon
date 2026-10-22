extends SceneTree
## Rendered regression: ground-front cutouts must keep their whole opaque silhouette.
## Run without --headless; colors isolate incorrect fragment-depth slicing.

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Sprite occlusion checks require a rendered window.")
		quit(1)
		return
	create_timer(30.0).timeout.connect(func() -> void: push_error("Occlusion test timeout."); quit(1))
	root.size = Vector2i(640, 480)
	var room: Node3D = (load("res://scenes/worlds/movement_test/movement_test.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(room)
	await process_frame
	var source_player: AnimatedSprite3D = room.get_node("Player/Visual") as AnimatedSprite3D
	var source_rock: Sprite3D
	for child: Node in room.get_node("Scenery").get_children():
		if child is Sprite3D and child.texture.resource_path.ends_with("rock_ink.svg"):
			source_rock = child as Sprite3D
			break
	var player: Sprite3D = _test_sprite(source_player, Vector2i(96, 96), Color.BLUE)
	var rock: Sprite3D = _test_sprite(source_rock, Vector2i(256, 256), Color.RED)
	room.queue_free()
	await process_frame
	var world: Node3D = Node3D.new()
	root.add_child(world)
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(100, 100)
	floor_mesh.mesh = plane
	var floor_material: StandardMaterial3D = StandardMaterial3D.new()
	floor_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_material.albedo_color = Color(0.3, 0.3, 0.3)
	floor_mesh.material_override = floor_material
	world.add_child(floor_mesh)
	world.add_child(player)
	world.add_child(rock)
	var camera: Camera3D = Camera3D.new()
	camera.fov = 35
	world.add_child(camera)
	camera.make_current()
	for pitch: float in [30.0, 60.0]:
		for heading: int in range(0, 360, 45):
			var toward: Vector3 = Vector3(sin(deg_to_rad(heading)), 0, cos(deg_to_rad(heading)))
			var distance: float = 14.0 if pitch == 30.0 else 32.0
			camera.position = toward * cos(deg_to_rad(pitch)) * distance + Vector3(0, 0.8 + sin(deg_to_rad(pitch)) * distance, 0)
			camera.look_at(Vector3(0, 0.8, 0))
			for player_front: bool in [true, false]:
				var sign_value: float = 1.0 if player_front else -1.0
				player.position.x = toward.x * 0.3 * sign_value
				player.position.z = toward.z * 0.3 * sign_value
				rock.position.x = -toward.x * 0.3 * sign_value
				rock.position.z = -toward.z * 0.3 * sign_value
				var front: Sprite3D = player if player_front else rock
				var back: Sprite3D = rock if player_front else player
				front.visible = true
				back.visible = false
				var isolated: Image = await _capture()
				back.visible = true
				var combined: Image = await _capture()
				var expected_blue: bool = player_front
				var samples: int = 0
				var sliced: int = 0
				# A two-pixel sampling grid catches slicing without millions of slow pixel reads.
				for y: int in range(0, isolated.get_height(), 2):
					for x: int in range(0, isolated.get_width(), 2):
						if _matches(isolated.get_pixel(x, y), expected_blue):
							samples += 1
							if not _matches(combined.get_pixel(x, y), expected_blue):
								sliced += 1
				_checks += 1
				if samples < 50 or sliced > 2:
					_failures += 1
					push_error("Cutout sliced at heading %d pitch %s player_front %s: %d / %d pixels" % [heading, pitch, player_front, sliced, samples])
	world.queue_free()
	await process_frame
	print("SPRITE_OCCLUSION_TEST_OK (%d checks)" % _checks if _failures == 0 else "SPRITE_OCCLUSION_TEST_FAILED (%d of %d)" % [_failures, _checks])
	quit(0 if _failures == 0 else 1)


func _test_sprite(source: SpriteBase3D, dimensions: Vector2i, color: Color) -> Sprite3D:
	var image: Image = Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var sprite: Sprite3D = Sprite3D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.pixel_size = source.pixel_size
	sprite.position.y = source.position.y
	sprite.offset = source.offset
	sprite.billboard = source.billboard
	sprite.alpha_cut = source.alpha_cut
	sprite.sorting_use_aabb_center = source.sorting_use_aabb_center
	sprite.no_depth_test = source.no_depth_test
	sprite.shaded = false
	return sprite


func _capture() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _matches(color: Color, blue: bool) -> bool:
	return color.b > 0.95 and color.r < 0.05 if blue else color.r > 0.95 and color.b < 0.05
