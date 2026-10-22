class_name ExplorationCameraRig
extends Node3D
## Independent perspective orbit camera. The composing world owns its target and locks.

@export var target: Node3D
@export var target_offset: Vector3 = Vector3(0, 0.85, 0)
@export_range(0.0, 360.0, 1.0) var initial_heading_degrees: float = 45.0
@export_range(1.0, 100.0, 0.1) var initial_distance: float = 22.0
@export_range(1.0, 100.0, 0.1) var min_distance: float = 14.0
@export_range(1.0, 100.0, 0.1) var max_distance: float = 32.0
@export_range(5.0, 85.0, 0.5) var min_pitch_degrees: float = 30.0
@export_range(5.0, 85.0, 0.5) var max_pitch_degrees: float = 60.0
@export_range(1.0, 100.0, 0.5) var field_of_view: float = 35.0
@export_range(0.1, 30.0, 0.1) var follow_speed: float = 12.0
@export_range(0.1, 30.0, 0.1) var rotation_speed: float = 14.0
@export_range(0.1, 30.0, 0.1) var zoom_speed: float = 8.0
@export_range(0.1, 10.0, 0.1) var zoom_step: float = 2.0

var _target_heading: float = 0.0
var _heading: float = 0.0
var _target_distance: float = 22.0
var _distance: float = 22.0
var _controls_enabled: bool = true
var _window_focused: bool = true

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	# Follow interpolated physics motion manually; never interpolate the camera twice.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	top_level = true
	global_basis = Basis.IDENTITY
	set_heading(initial_heading_degrees, true)
	set_distance(initial_distance, true)
	snap_to_target()


func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at: Vector3 = target.get_global_transform_interpolated().origin + target_offset
		global_position = global_position.lerp(at, 1.0 - exp(-follow_speed * delta))
	_heading = lerp_angle(_heading, _target_heading, 1.0 - exp(-rotation_speed * delta))
	_target_distance = _clamp_distance(_target_distance)
	_distance = lerpf(_distance, _target_distance, 1.0 - exp(-zoom_speed * delta))
	_apply_camera()


func _unhandled_input(event: InputEvent) -> void:
	if not _controls_enabled or not _window_focused or get_viewport().gui_get_focus_owner() != null:
		return
	if event is InputEventKey and (event.echo or event.ctrl_pressed or event.alt_pressed or event.meta_pressed):
		return
	if event.is_action_pressed(&"camera_rotate_left"):
		set_heading(get_target_heading() - 45.0)
	elif event.is_action_pressed(&"camera_rotate_right"):
		set_heading(get_target_heading() + 45.0)
	elif event.is_action_pressed(&"camera_zoom_in"):
		set_distance(_target_distance - zoom_step)
	elif event.is_action_pressed(&"camera_zoom_out"):
		set_distance(_target_distance + zoom_step)
	else:
		return
	get_viewport().set_input_as_handled()


func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled


func is_controls_enabled() -> bool:
	return _controls_enabled


func set_heading(degrees: float, snap: bool = false) -> void:
	_target_heading = deg_to_rad(wrapf(degrees, 0.0, 360.0))
	if snap:
		_heading = _target_heading
		if is_instance_valid(_camera):
			_apply_camera()


func get_target_heading() -> float:
	return wrapf(rad_to_deg(_target_heading), 0.0, 360.0)


func get_movement_basis() -> Basis:
	# Input uses the requested heading while the visible orbit catches up.
	return Basis(Vector3.UP, _target_heading)


func set_distance(distance: float, snap: bool = false) -> void:
	_target_distance = _clamp_distance(distance)
	if snap:
		_distance = _target_distance
		if is_instance_valid(_camera):
			_apply_camera()


func get_target_distance() -> float:
	return _target_distance


func snap_to_target() -> void:
	if is_instance_valid(target):
		global_position = target.global_position + target_offset
	_heading = _target_heading
	_distance = _target_distance
	_apply_camera()
	reset_physics_interpolation()


func _clamp_distance(distance: float) -> float:
	var lower: float = maxf(0.1, minf(min_distance, max_distance))
	var upper: float = maxf(lower, maxf(min_distance, max_distance))
	return clampf(distance, lower, upper)


func _apply_camera() -> void:
	var lower: float = _clamp_distance(-INF)
	var upper: float = _clamp_distance(INF)
	var fraction: float = inverse_lerp(lower, upper, _distance) if upper > lower else 0.0
	var close_pitch: float = clampf(min_pitch_degrees, 5.0, 85.0)
	var far_pitch: float = clampf(max_pitch_degrees, close_pitch, 85.0)
	var pitch: float = deg_to_rad(lerpf(close_pitch, far_pitch, clampf(fraction, 0.0, 1.0)))
	var orientation: Basis = Basis.from_euler(Vector3(-pitch, _heading, 0.0))
	_camera.global_transform = Transform3D(orientation, global_position + orientation.z * _distance)
	_camera.fov = field_of_view


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_window_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_window_focused = true
