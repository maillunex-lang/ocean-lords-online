extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var sea: ShaderMaterial = game.sea_mesh.material_override
	assert(sea.get_shader_parameter("use_texture_details") == true, "Original textures are not enabled")
	var sizes := {
		"normal_medium": Vector2i(1024, 1024),
		"normal_detail": Vector2i(512, 512),
		"foam_mask": Vector2i(1024, 1024),
		"foam_noise": Vector2i(512, 512)
	}
	for key in sizes:
		var texture: Texture2D = sea.get_shader_parameter(key)
		assert(texture != null, "Missing original image " + key)
		var expected_size: Vector2i = sizes[key]
		assert(texture.get_width() == expected_size.x and texture.get_height() == expected_size.y, "Wrong source texture size: " + key)
	assert(is_equal_approx(float(sea.get_shader_parameter("normal_strength")), 1.10), "Original normal map detail is too weak")
	assert(is_equal_approx(float(sea.get_shader_parameter("foam_amount")), 0.82), "Original foam masks are too weak")
	var shader_source: String = sea.shader.code
	assert(shader_source.contains("sea_world_xz * 0.12"), "Foam must use world-space texture UVs")
	assert(shader_source.contains("foam_pattern * (0.20 + crest * 0.80)"), "Foam is not visible between crests")
	assert(is_equal_approx(sea.get_shader_parameter("wave_height"), game.WAVE_HEIGHT))
	game._update_celestial_discs()
	var initial_sun_bearing: Vector3 = (game.sun_disc.global_position - game.camera.global_position).normalized()
	game.ship.rotate_y(1.2)
	game._update_camera(1.0)
	game._update_celestial_discs()
	var rotated_sun_bearing: Vector3 = (game.sun_disc.global_position - game.camera.global_position).normalized()
	assert(initial_sun_bearing.distance_to(rotated_sun_bearing) < 0.001, "Sun still camera-heading locked")
	game._physics_process(1.0 / 30.0)
	assert(float(sea.get_shader_parameter("ship_speed")) > 0.0, "Wake has no ship speed")
	assert((sea.get_shader_parameter("ship_position") as Vector3).distance_to(game.ship.global_position) < 0.01, "Wake not following the ship")
	print("ORIGINAL_OCEAN_PASS: 4 images, waves, stable sun, moving boat wake")
	quit(0)
