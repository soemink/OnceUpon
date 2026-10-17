extends Node3D
## Standalone development room; L simulates a dialogue/menu movement lock.

@onready var _player: ExplorationPlayer = %Player
@onready var _camera_rig: Node3D = %CameraRig
@onready var _status: Label = %Status
@onready var _spawn_position: Vector3 = _player.position


func _process(_delta: float) -> void:
	var state: String = String(_player.motion).capitalize()
	if not _player.is_movement_enabled():
		state = "Movement locked — press L to resume"
	_status.text = "%s  |  Facing %s" % [state, _player.facing]


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_L:
			_player.set_movement_enabled(not _player.is_movement_enabled())
			get_viewport().set_input_as_handled()
		KEY_R:
			_player.set_movement_enabled(true)
			_player.position = _spawn_position
			_player.velocity = Vector3.ZERO
			_player.reset_physics_interpolation()
			_camera_rig.snap_to_target()
			get_viewport().set_input_as_handled()
