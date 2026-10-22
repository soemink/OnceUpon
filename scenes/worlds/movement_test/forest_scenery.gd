extends Node3D
## Temporary illustrated art pass. Physical layout remains owned by the test room.

const TREE_PATH: String = "res://assets/art/environments/forest_style_test/tree_ink.png"
const GROUND_PATH: String = "res://assets/art/environments/forest_style_test/ground_paper.png"
const ROCK: Texture2D = preload("res://assets/art/environments/forest_style_test/rock_ink.svg")
const FERN: Texture2D = preload("res://assets/art/environments/forest_style_test/fern_ink.svg")

var _tree_texture: Texture2D
var _shadow_material: StandardMaterial3D
var _player_shadow: MeshInstance3D

@onready var _player: Node3D = get_parent().get_node("Player") as Node3D


func _ready() -> void:
	_tree_texture = load(TREE_PATH) as Texture2D
	_create_ground()
	_create_path()
	_create_shadows()
	var trees: Array[Vector3] = [
		Vector3(-9, 0, -8), Vector3(-11, 0, -3), Vector3(-9.5, 0, 2),
		Vector3(-8, 0, 8.5), Vector3(-3.8, 0, -9.8), Vector3(0.5, 0, -10.5),
		Vector3(6.5, 0, -9), Vector3(10, 0, -5), Vector3(10.7, 0, 1),
		Vector3(10.5, 0, 7), Vector3(-12.8, 0, -10), Vector3(-7, 0, -13),
		Vector3(1, 0, -14), Vector3(8, 0, -13), Vector3(14, 0, -6),
	]
	for index: int in range(trees.size()):
		_create_tree(index, trees[index], 5.0 + float(index % 3) * 0.45)
	# Each illustrated stone follows the actual retained obstacle footprint.
	_stone_row(Vector3(3, 0, -2.65), Vector3(0, 0, 0.85), 7, 1.4)
	_stone_row(Vector3(-6.5, 0, -4), Vector3(0.85, 0, 0), 7, 1.4)
	_stone_row(Vector3(-6.5, 0, -3.8), Vector3(0, 0, 0.85), 7, 1.4)
	# Continuous illustrated borders explain the collision perimeter at every orbit.
	_stone_row(Vector3(-11.7, 0, -12), Vector3(0.9, 0, 0), 27, 1.2)
	_stone_row(Vector3(-11.7, 0, 12), Vector3(0.9, 0, 0), 27, 1.2)
	_stone_row(Vector3(-12, 0, -11.7), Vector3(0, 0, 0.9), 27, 1.2)
	_stone_row(Vector3(12, 0, -11.7), Vector3(0, 0, 0.9), 27, 1.2)
	for index: int in range(32):
		var angle: float = float(index) * 2.39996
		var radius: float = 5.5 + float(index % 5) * 1.1
		var at: Vector3 = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		var fern: Sprite3D = _illustration(FERN, 0.55 + float(index % 3) * 0.12)
		fern.position = at
		add_child(fern)


func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		var at: Vector3 = _player.get_global_transform_interpolated().origin
		_player_shadow.global_position = Vector3(at.x, 0.013, at.z)


func _create_ground() -> void:
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.name = "IllustratedGround"
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(100, 100)
	ground.mesh = plane
	var material: StandardMaterial3D = _flat_material(Color(0.83, 0.86, 0.73))
	material.albedo_texture = load(GROUND_PATH) as Texture2D
	material.uv1_scale = Vector3(14, 14, 1)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ground.material_override = material
	ground.position.y = 0.002
	add_child(ground)


func _create_path() -> void:
	# A flat irregular strip, with vertex tint variation rather than lit 3D sides.
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for step: int in range(151):
		var z: float = -60.0 + float(step) * 0.8
		var center: float = sin(z * 0.17) * 1.25 - 0.6
		var width: float = 1.1 + sin(z * 1.7) * 0.09
		for side: float in [-1.0, 1.0]:
			surface.set_color(Color(0.73 + sin(z) * 0.018, 0.63, 0.43))
			surface.add_vertex(Vector3(center + width * side, 0.009, z))
	var path: MeshInstance3D = MeshInstance3D.new()
	path.name = "WindingPath"
	path.mesh = surface.commit()
	var material: StandardMaterial3D = _flat_material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	path.material_override = material
	add_child(path)


func _create_shadows() -> void:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(0.12, 0.17, 0.13, 0.26))
	gradient.set_color(1, Color(0.12, 0.17, 0.13, 0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0)
	_shadow_material = _flat_material(Color.WHITE)
	_shadow_material.albedo_texture = texture
	_shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shadow_material.render_priority = -1
	_player_shadow = _shadow(Vector3(0, 0.013, 5), Vector2(1.1, 0.6))
	_player_shadow.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _create_tree(index: int, at: Vector3, height: float) -> void:
	var tree: StaticBody3D = StaticBody3D.new()
	tree.name = "Tree%d" % index
	tree.position = at
	add_child(tree)
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = 0.38
	cylinder.height = 2.0
	shape.shape = cylinder
	shape.position.y = 1.0
	tree.add_child(shape)
	var sprite: Sprite3D = _illustration(_tree_texture, height)
	sprite.name = "Illustration"
	sprite.modulate = Color(1.0 - float(index % 3) * 0.035, 1.0 - float(index % 2) * 0.02, 1)
	tree.add_child(sprite)
	_shadow(at + Vector3(0, 0.014, 0), Vector2(3.0, 1.8))


func _stone_row(start: Vector3, direction: Vector3, count: int, height: float) -> void:
	for index: int in range(count):
		var stone: Sprite3D = _illustration(ROCK, height)
		stone.position = start + direction * index
		stone.flip_h = index % 2 == 0
		add_child(stone)


func _illustration(texture: Texture2D, height: float) -> Sprite3D:
	var sprite: Sprite3D = Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = height / float(texture.get_height())
	# Sort whole transparent pictures by grounded origins; opaque depth cutouts slice
	# through each other when the player's full billboard meets upright scenery.
	sprite.offset.y = float(texture.get_height()) * 0.5
	sprite.sorting_use_aabb_center = false
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.shaded = false
	sprite.double_sided = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return sprite


func _shadow(at: Vector3, size: Vector2) -> MeshInstance3D:
	var shadow: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = size
	shadow.mesh = plane
	shadow.material_override = _shadow_material
	shadow.position = at
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	return shadow


func _flat_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material
