class_name ExplorationPlayer
extends CharacterBody3D
## Keyboard locomotion for a sprite character in a 3D world.
## The composing scene supplies its camera and controls movement locks.

@export_range(0.0, 20.0, 0.1) var walk_speed: float = 3.0
@export_range(0.0, 30.0, 0.1) var run_speed: float = 4.5
@export var movement_camera: Camera3D

var facing: StringName = &"down"
var motion: StringName = &"idle"

var _movement_enabled: bool = true
var _window_focused: bool = true

@onready var _visual: AnimatedSprite3D = $Visual


func _physics_process(delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO
	if _movement_enabled and _window_focused:
		direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var running: bool = Input.is_action_pressed(&"run")
	var speed: float = run_speed if running else walk_speed
	var movement: Vector3 = _ground_direction(direction) * speed
	velocity.x = movement.x
	velocity.z = movement.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity += get_gravity() * delta
	move_and_slide()

	if not direction.is_zero_approx():
		if absf(direction.x) > absf(direction.y):
			facing = &"right" if direction.x > 0.0 else &"left"
		else:
			facing = &"down" if direction.y > 0.0 else &"up"
	var actual: Vector3 = get_real_velocity()
	var moving: bool = Vector2(actual.x, actual.z).length() > 0.05
	motion = (&"run" if running else &"walk") if moving else &"idle"
	_update_visual()


func set_movement_enabled(enabled: bool) -> void:
	_movement_enabled = enabled
	if not enabled:
		_stop_horizontal_movement()


func is_movement_enabled() -> bool:
	return _movement_enabled


func _ground_direction(direction: Vector2) -> Vector3:
	if not is_instance_valid(movement_camera):
		return Vector3(direction.x, 0, direction.y)
	var right: Vector3 = movement_camera.global_basis.x
	var back: Vector3 = movement_camera.global_basis.z
	right.y = 0.0
	back.y = 0.0
	return (right.normalized() * direction.x + back.normalized() * direction.y).limit_length(1.0)


func _stop_horizontal_movement() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	motion = &"idle"
	if is_instance_valid(_visual):
		_update_visual()


func _update_visual() -> void:
	var animation: StringName = StringName("%s_%s" % [motion, facing])
	if _visual.animation != animation:
		_visual.play(animation)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_window_focused = false
		_stop_horizontal_movement()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_window_focused = true
