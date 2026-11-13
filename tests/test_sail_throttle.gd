extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.speed = 10.0
	scene._on_sails_changed(0.0)
	assert(scene.throttle == 0.0)
	for i in range(60):
		scene._physics_process(1.0 / 60.0)
	assert(scene.speed < 2.0, "Sails at zero should slow ship in one second")
	var stopped: float = scene.speed
	scene._on_sails_changed(1.0)
	for i in range(60):
		scene._physics_process(1.0 / 60.0)
	assert(scene.speed > stopped + 2.5, "Sails at full should accelerate ship")
	print("SAIL_THROTTLE_PASS: reef and accelerate affect actual ship speed")
	quit()
