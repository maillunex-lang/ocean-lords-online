extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.sail_material != null)
	assert(scene.ship_visual.get_child_count() >= 7)
	assert(scene.sun_disc.visible and not scene.moon_disc.visible)
	scene._toggle_day_night()
	assert(scene.moon_disc.visible and not scene.sun_disc.visible)
	scene._toggle_day_night()
	assert(scene.sun_disc.visible and not scene.moon_disc.visible)
	print("SAILS_WIND_CELESTIAL_SHIP_MATERIAL_PASS")
	quit(0)
