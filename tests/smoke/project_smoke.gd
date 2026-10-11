extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var main_path: String = str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if not main_path.begins_with("res://") and not main_path.begins_with("uid://"):
		push_error("The configured main scene must use a res:// path or uid:// reference.")
		quit(1)
		return

	var main_resource: Resource = load(main_path)
	if main_resource == null:
		push_error("Could not load the configured main scene: " + main_path)
		quit(1)
		return
	if not main_resource is PackedScene:
		push_error("The configured main scene is not a PackedScene: " + main_path)
		quit(1)
		return

	var main_scene: PackedScene = main_resource as PackedScene
	var instance: Node = main_scene.instantiate()
	if instance == null:
		push_error("Could not instantiate the configured main scene: " + main_path)
		quit(1)
		return

	root.add_child(instance)
	current_scene = instance
	await process_frame
	await process_frame
	print("PROJECT_SMOKE_OK")
	quit(0)
