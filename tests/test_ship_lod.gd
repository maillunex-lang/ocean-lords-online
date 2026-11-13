extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    assert(packed != null, "Main scene missing")
    var scene: Node = packed.instantiate()
    root.add_child(scene)
    await process_frame
    assert(scene.ship_lod_nodes.size() == 3, "Expected 3 imported ship LODs")
    var expected := [60000, 16000, 6494]
    for i in range(3):
        var mesh_instances: Array[MeshInstance3D] = []
        _find_meshes(scene.ship_lod_nodes[i], mesh_instances)
        assert(mesh_instances.size() > 0, "LOD mesh missing")
        var faces := 0
        for item in mesh_instances:
            for surface in range(item.mesh.get_surface_count()):
                faces += item.mesh.surface_get_array_index_len(surface) / 3
        assert(absf(float(faces - expected[i])) < 100.0, "Wrong triangle count for LOD %d: %d" % [i, faces])
        scene._set_ship_lod(i)
        assert(scene.active_ship_lod == i, "LOD state incorrect")
        for j in range(3):
            assert(scene.ship_lod_nodes[j].visible == (j == i), "LOD visibility mismatch")
    assert(absf(scene.ship_lod_nodes[0].scale.x * 6.278683 - 24.0) < 0.1, "Ship should be 24m")
    assert(absf(scene.ship_lod_nodes[0].rotation.y - PI / 2.0) < 0.01, "Ship long axis must face -Z")
    assert(scene.camera_zoom == 1.0)
    scene._set_zoom(0.1)
    assert(is_equal_approx(scene.camera_zoom, 0.65))
    scene._set_zoom(5.0)
    assert(is_equal_approx(scene.camera_zoom, 1.85))
    scene._set_zoom(1.0)
    scene.camera.global_position = scene.ship.global_position + Vector3(0, 20, 30)
    scene._update_ship_lod()
    assert(scene.active_ship_lod == 0)
    scene.camera.global_position = scene.ship.global_position + Vector3(0, 40, 55)
    scene._update_ship_lod()
    assert(scene.active_ship_lod == 1)
    scene.camera.global_position = scene.ship.global_position + Vector3(0, 40, 140)
    scene._update_ship_lod()
    assert(scene.active_ship_lod == 2)
    print("SHIP_LOD_TEST_PASS: 3 imported LODs, triangle counts, visibility and distances")
    quit(0)

func _find_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D:
        result.append(node as MeshInstance3D)
    for child in node.get_children():
        _find_meshes(child, result)
