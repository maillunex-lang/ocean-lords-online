extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var scene = load("res://scenes/main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    var material: ShaderMaterial = scene.sea_mesh.material_override
    assert(material.get_shader_parameter("use_texture_details") == true, "Ocean texture details disabled")
    for key in ["normal_medium","normal_detail","foam_mask","foam_noise"]:
        assert(material.get_shader_parameter(key) is Texture2D, "Missing ocean texture: " + key)
    assert(ProjectSettings.get_setting("display/window/handheld/orientation") == 0, "Landscape orientation not fixed")
    print("OCEAN_TEXTURES_PASS: 4 textures active and landscape locked")
    quit(0)
