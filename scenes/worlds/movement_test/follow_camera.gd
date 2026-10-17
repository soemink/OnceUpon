extends Node3D
## Independent fixed-angle camera anchor, also usable as a cutscene handoff.

@export var target: Node3D
@export_range(0.1, 30.0, 0.1) var follow_speed: float = 12.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	snap_to_target()


func _process(delta: float) -> void:
	if is_instance_valid(target):
		var target_position: Vector3 = target.get_global_transform_interpolated().origin
		global_position = global_position.lerp(target_position, 1.0 - exp(-follow_speed * delta))


func snap_to_target() -> void:
	if is_instance_valid(target):
		global_position = target.global_position
