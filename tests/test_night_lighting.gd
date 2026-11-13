extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var scene = load("res://scenes/main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    scene._toggle_day_night()
    assert(scene.is_night)
    assert(scene.sun_light.light_energy >= 0.7, "Moonlight is too weak")
    assert(scene.world_environment.environment.ambient_light_energy >= 1.2, "Ambient night light too weak")
    var night_water: Color = (scene.sea_mesh.material_override as ShaderMaterial).get_shader_parameter("deep_color")
    assert(night_water.b >= 0.15, "Night water too dark")
    scene._toggle_day_night()
    assert(not scene.is_night)
    assert(scene.sun_light.light_color == Color.WHITE, "Daylight color not restored")
    assert(is_equal_approx(scene.world_environment.environment.ambient_light_energy, 1.0))
    print("NIGHT_LIGHTING_PASS")
    quit(0)
