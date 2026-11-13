extends Node3D
## Offline prototype: generated sea, simple ship, isometric camera, touch/keyboard steering.
## No multiplayer, persistence, cannon physics, or production ocean simulation yet.

var ship: Node3D
var camera: Camera3D
var speed: float = 0.0
var throttle: float = 0.7
var turn_input: float = 0.0
var touch_turn: float = 0.0
var touch_enabled: bool = false
var touch_sails: float = 0.7
var hud: Label
var hud_help: Label
var hud_layer: CanvasLayer
var day_night_button: Button
var is_night: bool = false
var world_environment: WorldEnvironment
var sun_light: DirectionalLight3D
var sea_mesh: MeshInstance3D
var sea_material: StandardMaterial3D
const TOUCH_HELM = preload("res://scripts/touch_helm.gd")
const OCEAN_SHADER = preload("res://shaders/ocean_mobile.gdshader")
const SAIL_SHADER = preload("res://shaders/sail_wind.gdshader")
const WOOD_SHADER = preload("res://shaders/ship_wood.gdshader")
const GLOW_SHADER = preload("res://shaders/celestial_glow.gdshader")
var sail_material: ShaderMaterial
var sun_disc: MeshInstance3D
var moon_disc: MeshInstance3D
var wind_direction := Vector2(0.94, 0.34)
var wind_strength := 0.8
const WATER_HEIGHT := -0.45
const WAVE_HEIGHT := 0.58
const WAVE_SCALE := 0.18
const WAVE_SPEED := 0.75
# World-space bearings stay constant when the boat/camera turns.
const SUN_SKY_BEARING := Vector3(-0.74, 0.28, -0.61)
const MOON_SKY_BEARING := Vector3(0.45, 0.34, -0.82)
var ocean_time: float = 0.0
var ship_visual: Node3D
const MESHY_LOD_PATHS := [
    "res://assets/ships/brigantine_lod0.glb",
    "res://assets/ships/brigantine_lod1.glb",
    "res://assets/ships/brigantine_lod2.glb"
]
const LOD_DISTANCES := [65.0, 120.0]
const SHIP_LENGTH_METERS := 24.0
var camera_zoom: float = 1.0
var zoom_label: Label
var zoom_minus: Button
var zoom_plus: Button
var ship_lod_nodes: Array[Node3D] = []
var active_ship_lod: int = -1
var current_heel: float = 0.0

const MAX_SPEED := 12.0
const ACCEL := 3.5
const SAIL_BRAKE := 9.0
const TURN_RATE := 0.65

func _ready() -> void:
	_create_world()
	_create_ship()
	_create_sails()
	_create_celestial_discs()
	_create_camera()
	_create_hud()
	_create_touch_controls()

func _create_world() -> void:
	world_environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.42, 0.65, 0.74)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.77, 0.85)
	env.ambient_light_energy = 1.0
	world_environment.environment = env
	add_child(world_environment)
	sun_light = DirectionalLight3D.new()
	sun_light.rotation_degrees = Vector3(-50, -30, 0)
	sun_light.light_color = Color.WHITE
	sun_light.light_energy = 1.4
	add_child(sun_light)
	sea_mesh = MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(600, 600)
	mesh.subdivide_width = 128
	mesh.subdivide_depth = 128
	sea_mesh.mesh = mesh
	var ocean_material := ShaderMaterial.new()
	ocean_material.shader = OCEAN_SHADER
	var texture_paths := {
		"normal_medium": "res://assets/ocean/ocean_normal_medium.png",
		"normal_detail": "res://assets/ocean/ocean_normal_detail.png",
		"foam_mask": "res://assets/ocean/ocean_foam_mask.png",
		"foam_noise": "res://assets/ocean/ocean_foam_noise.png"
	}
	var textures_ready := true
	for parameter in texture_paths:
		var path: String = texture_paths[parameter]
		if ResourceLoader.exists(path):
			var loaded: Resource = load(path)
			if loaded is Texture2D:
				ocean_material.set_shader_parameter(parameter, loaded)
			else:
				textures_ready = false
		else:
			textures_ready = false
	ocean_material.set_shader_parameter("use_texture_details", textures_ready)
	ocean_material.set_shader_parameter("wave_height", WAVE_HEIGHT)
	ocean_material.set_shader_parameter("wave_scale", WAVE_SCALE)
	ocean_material.set_shader_parameter("sun_direction", SUN_SKY_BEARING.normalized())
	ocean_material.set_shader_parameter("normal_strength", 1.10)
	ocean_material.set_shader_parameter("foam_amount", 0.82)
	sea_mesh.material_override = ocean_material
	sea_mesh.position.y = WATER_HEIGHT
	add_child(sea_mesh)

func _make_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	part.material_override = material
	parent.add_child(part)

func _create_ship() -> void:
	ship = Node3D.new()
	ship.name = "PlayerShip"
	add_child(ship)
	ship_visual = Node3D.new()
	ship.add_child(ship_visual)
	_make_box(ship_visual, Vector3(2.1, 0.8, 5.6), Vector3(0, 0.4, 0), Color(0.35, 0.19, 0.1))
	_make_box(ship_visual, Vector3(1.6, 0.2, 4.4), Vector3(0, 0.85, 0), Color(0.59, 0.39, 0.21))
	_make_box(ship_visual, Vector3(0.14, 4.2, 0.14), Vector3(0, 2.9, -0.45), Color(0.31, 0.18, 0.1))
	_make_box(ship, Vector3(2.3, 2.6, 0.09), Vector3(0, 3.0, -0.45), Color(0.88, 0.84, 0.71))
	_make_box(ship, Vector3(0.13, 2.8, 0.13), Vector3(0, 2.15, 1.6), Color(0.31, 0.18, 0.1))
	_make_box(ship, Vector3(1.6, 1.7, 0.09), Vector3(0, 2.5, 1.6), Color(0.85, 0.8, 0.67))
	_try_load_meshy_ship()

func _try_load_meshy_ship() -> void:
	# All LODs are imported and cached once; visibility changes cost no IO.
	for path in MESHY_LOD_PATHS:
		if not ResourceLoader.exists(path):
			push_warning("Brigantine LOD missing: " + path)
			return
	var imported: Array[Node3D] = []
	for path in MESHY_LOD_PATHS:
		var resource: Resource = load(path)
		if not resource is PackedScene:
			push_warning("Invalid brigantine GLB: " + path)
			for node in imported:
				node.queue_free()
			return
		var model: Node = (resource as PackedScene).instantiate()
		if not model is Node3D:
			model.queue_free()
			for node in imported:
				node.queue_free()
			return
		imported.append(model as Node3D)
	for child in ship_visual.get_children():
		child.queue_free()
	# The old primitive sails were direct ship children, not part of ship_visual.
	for child in ship.get_children():
		if child != ship_visual:
			child.queue_free()
	# Meshy Preview GLB was generated with its long axis along X, not Godot -Z.
	# Derive the scale from the imported mesh, then align every LOD identically.
	var reference_bounds := _mesh_bounds(imported[0])
	if reference_bounds.size.x <= 0.01:
		push_warning("Meshy ship bounds invalid; retaining primitive fallback")
		for model in imported:
			model.queue_free()
		return
	var uniform_scale: float = SHIP_LENGTH_METERS / reference_bounds.size.x
	var center: Vector3 = reference_bounds.get_center()
	var wood := ShaderMaterial.new()
	wood.shader = WOOD_SHADER
	for model in imported:
		for part in model.get_children():
			if part is MeshInstance3D:
				(part as MeshInstance3D).material_override = wood
		model.scale = Vector3.ONE * uniform_scale
		model.rotation.y = PI / 2.0
		# Keep the center of the hull close to the sea surface.
		model.position = Vector3(0.0, 7.8, 0.0) - (Basis(Vector3.UP, PI / 2.0) * center) * uniform_scale
		ship_visual.add_child(model)
		model.visible = false
	ship_lod_nodes = imported
	_set_ship_lod(0)


func _create_sails() -> void:
	# Preview GLB lacks sail cloth. Lightweight double-sided cloth is added
	# separately to the hull so it remains visible across all mesh LODs.
	sail_material = ShaderMaterial.new()
	sail_material.shader = SAIL_SHADER
	sail_material.set_shader_parameter("wind_direction", wind_direction)
	sail_material.set_shader_parameter("wind_strength", wind_strength * throttle)
	for mast_z in [-3.0, 5.0]:
		for height in [11.0, 15.0]:
			var cloth := MeshInstance3D.new()
			var plane := PlaneMesh.new()
			plane.size = Vector2(6.4 if height < 13.0 else 5.1, 4.1)
			plane.subdivide_width = 16
			plane.subdivide_depth = 12
			cloth.mesh = plane
			cloth.rotation_degrees.x = 90.0
			cloth.position = Vector3(0, height, mast_z)
			cloth.material_override = sail_material
			ship_visual.add_child(cloth)


func _create_celestial_discs() -> void:
	sun_disc = _make_glow(Color(1.0, 0.78, 0.38), 1.7)
	moon_disc = _make_glow(Color(0.58, 0.75, 1.0), 1.2)
	moon_disc.visible = false


func _make_glow(color: Color, intensity: float) -> MeshInstance3D:
	var disc := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(18.0, 18.0)
	disc.mesh = quad
	var material := ShaderMaterial.new()
	material.shader = GLOW_SHADER
	material.set_shader_parameter("glow_color", color)
	material.set_shader_parameter("glow_intensity", intensity)
	disc.material_override = material
	add_child(disc)
	return disc


func _update_celestial_discs() -> void:
	if camera == null:
		return
	# Keep sun/moon at constant WORLD bearings, never locked to camera rotation.
	# Translate with the camera only to avoid running out of draw distance.
	var center := camera.global_position
	sun_disc.global_position = center + SUN_SKY_BEARING.normalized() * 220.0
	moon_disc.global_position = center + MOON_SKY_BEARING.normalized() * 220.0
	sun_disc.look_at(camera.global_position, Vector3.UP)
	moon_disc.look_at(camera.global_position, Vector3.UP)


func _mesh_bounds(node: Node3D) -> AABB:
	var bounds := AABB()
	var initialized := false
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			var local_bounds := mesh_instance.transform * mesh_instance.get_aabb()
			bounds = bounds.merge(local_bounds) if initialized else local_bounds
			initialized = true
	return bounds


func _set_ship_lod(index: int) -> void:
	if ship_lod_nodes.is_empty() or index == active_ship_lod:
		return
	active_ship_lod = clampi(index, 0, ship_lod_nodes.size() - 1)
	for i in range(ship_lod_nodes.size()):
		ship_lod_nodes[i].visible = i == active_ship_lod


func _update_ship_lod() -> void:
	if ship_lod_nodes.is_empty() or camera == null:
		return
	var distance: float = camera.global_position.distance_to(ship.global_position)
	var wanted := 0
	if distance > LOD_DISTANCES[1]:
		wanted = 2
	elif distance > LOD_DISTANCES[0]:
		wanted = 1
	_set_ship_lod(wanted)


func _create_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 49.0
	add_child(camera)
	_update_camera(1.0)

func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	hud = Label.new()
	hud.position = Vector2(24, 22)
	hud.add_theme_font_size_override("font_size", 26)
	hud_layer.add_child(hud)
	hud_help = Label.new()
	hud_help.text = "Руль: слева   •   Паруса: справа"
	hud_help.add_theme_font_size_override("font_size", 19)
	hud_layer.add_child(hud_help)
	day_night_button = Button.new()
	day_night_button.text = "☾ Ночь"
	day_night_button.custom_minimum_size = Vector2(150, 66)
	day_night_button.add_theme_font_size_override("font_size", 23)
	day_night_button.pressed.connect(_toggle_day_night)
	hud_layer.add_child(day_night_button)
	zoom_minus = Button.new()
	zoom_minus.text = "−"
	zoom_minus.custom_minimum_size = Vector2(64, 64)
	zoom_minus.add_theme_font_size_override("font_size", 32)
	zoom_minus.pressed.connect(func(): _set_zoom(camera_zoom * 1.2))
	hud_layer.add_child(zoom_minus)
	zoom_plus = Button.new()
	zoom_plus.text = "+"
	zoom_plus.custom_minimum_size = Vector2(64, 64)
	zoom_plus.add_theme_font_size_override("font_size", 32)
	zoom_plus.pressed.connect(func(): _set_zoom(camera_zoom / 1.2))
	hud_layer.add_child(zoom_plus)
	_reposition_hud()
	get_viewport().size_changed.connect(_reposition_hud)


func _reposition_hud() -> void:
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var screen: Vector2i = DisplayServer.screen_get_size()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var left_margin: float = 24.0
	var top_margin: float = 24.0
	if safe.size.x > 0 and screen.x > 0 and screen.y > 0:
		left_margin = maxf(24.0, float(safe.position.x) * viewport_size.x / float(screen.x) + 16.0)
		top_margin = maxf(24.0, float(safe.position.y) * viewport_size.y / float(screen.y) + 16.0)
	hud.position = Vector2(left_margin, top_margin)
	hud_help.position = Vector2(left_margin, top_margin + 36.0)
	var right_margin: float = 24.0
	if safe.size.x > 0 and screen.x > 0:
		right_margin = maxf(24.0, float(screen.x - safe.end.x) * viewport_size.x / float(screen.x) + 16.0)
	day_night_button.position = Vector2(viewport_size.x - right_margin - day_night_button.custom_minimum_size.x, top_margin)
	zoom_plus.position = Vector2(viewport_size.x - right_margin - 64.0, top_margin + 78.0)
	zoom_minus.position = Vector2(viewport_size.x - right_margin - 64.0, top_margin + 150.0)

func _set_zoom(value: float) -> void:
	camera_zoom = clampf(value, 0.65, 1.85)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		_set_zoom(camera_zoom / event.factor)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(camera_zoom / 1.12)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(camera_zoom * 1.12)


func _toggle_day_night() -> void:
	is_night = not is_night
	var env := world_environment.environment
	sun_disc.visible = not is_night
	moon_disc.visible = is_night
	if is_night:
		env.background_color = Color(0.075, 0.13, 0.23)
		env.ambient_light_color = Color(0.34, 0.43, 0.59)
		env.ambient_light_energy = 1.3
		sun_light.light_color = Color(0.58, 0.72, 1.0)
		sun_light.light_energy = 0.72
		(sea_mesh.material_override as ShaderMaterial).set_shader_parameter("sun_glitter", 0.18)
		(sea_mesh.material_override as ShaderMaterial).set_shader_parameter("sun_direction", MOON_SKY_BEARING.normalized())
		day_night_button.text = "☀ День"
		(sea_mesh.material_override as ShaderMaterial).set_shader_parameter("deep_color", Color(0.035, 0.095, 0.16))
		(sea_mesh.material_override as ShaderMaterial).set_shader_parameter("crest_color", Color(0.11, 0.23, 0.33))
	else:
		env.background_color = Color(0.42, 0.65, 0.74)
		env.ambient_light_color = Color(0.65, 0.77, 0.85)
		env.ambient_light_energy = 1.0
		sun_light.light_color = Color.WHITE
		sun_light.light_energy = 1.4
		(sea_mesh.material_override as ShaderMaterial).set_shader_parameter("sun_glitter", 0.32)
		(sea_mesh.material_override as ShaderMaterial).set_shader_parameter("sun_direction", SUN_SKY_BEARING.normalized())
		day_night_button.text = "☾ Ночь"
		(sea_mesh.material_override as ShaderMaterial).set_shader_parameter("deep_color", Color(0.025, 0.16, 0.22))
		(sea_mesh.material_override as ShaderMaterial).set_shader_parameter("crest_color", Color(0.10, 0.38, 0.43))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_N:
		_toggle_day_night()

func _create_touch_controls() -> void:
	var controls: Control = TOUCH_HELM.new()
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	layer.add_child(controls)
	controls.connect("helm_changed", Callable(self, "_on_helm_changed"))
	controls.connect("sails_changed", Callable(self, "_on_sails_changed"))

func _on_helm_changed(value: float) -> void:
	touch_turn = value
	touch_enabled = absf(value) > 0.01

func _on_sails_changed(value: float) -> void:
	touch_sails = value
	throttle = value

func _physics_process(delta: float) -> void:
	var steer := Input.get_axis("ui_left", "ui_right")
	if touch_enabled:
		steer = touch_turn
	turn_input = move_toward(turn_input, steer, delta * 2.5)
	var sail_change := Input.get_axis("ui_down", "ui_up")
	throttle = clampf(throttle + sail_change * delta * 0.35, 0.0, 1.0)
	# The right-hand sail control changes actual thrust, not just a HUD value.
	# Reefing to zero rapidly bleeds speed; deploying sail accelerates gradually.
	var target_speed := throttle * MAX_SPEED
	var response := ACCEL * (0.35 + throttle * 0.65) if speed < target_speed else SAIL_BRAKE
	speed = move_toward(speed, target_speed, response * delta)
	ship.rotate_y(-turn_input * TURN_RATE * delta * (0.35 + speed / MAX_SPEED * 0.65))
	ship.translate_object_local(Vector3(0, 0, -speed * delta))
	ocean_time += delta
	var water_shader := sea_mesh.material_override as ShaderMaterial
	water_shader.set_shader_parameter("ship_position", ship.global_position)
	water_shader.set_shader_parameter("ship_forward", -ship.global_basis.z)
	water_shader.set_shader_parameter("ship_speed", speed)
	wind_strength = 0.8 + 0.18 * sin(ocean_time * 0.27)
	sail_material.set_shader_parameter("wind_strength", wind_strength * throttle)
	_update_ship_buoyancy(delta)
	hud.text = "OCEAN LORDS  |  %.1f уз  |  Паруса %d%%" % [speed, roundi(throttle * 100)]
	_update_camera(delta)
	_update_celestial_discs()
	_update_ship_lod()

func _wave_height_at(pos: Vector3, t: float) -> float:
	var a := (pos.x * 0.87 + pos.z * 0.49) * WAVE_SCALE + t * WAVE_SPEED
	var b := (pos.x * -0.43 + pos.z * 0.91) * WAVE_SCALE * 1.6 - t * WAVE_SPEED * 0.7
	return WAVE_HEIGHT * (sin(a) + 0.45 * sin(b))

func _update_ship_buoyancy(delta: float) -> void:
	# A cheap deterministic three-sample buoyancy approximation.
	# Not rigid-body hydrodynamics; collisions and network authority come later.
	var origin := ship.global_position
	var forward := ship.global_basis.z.normalized()
	var right := ship.global_basis.x.normalized()
	var front_height := _wave_height_at(origin - forward * 2.0, ocean_time)
	var back_height := _wave_height_at(origin + forward * 2.0, ocean_time)
	var left_height := _wave_height_at(origin - right * 0.8, ocean_time)
	var right_height := _wave_height_at(origin + right * 0.8, ocean_time)
	var center_height := _wave_height_at(origin, ocean_time)
	ship_visual.position.y = lerpf(ship_visual.position.y, center_height, clampf(delta * 3.0, 0.0, 1.0))
	var target_pitch := atan2(front_height - back_height, 4.0)
	var target_roll := atan2(left_height - right_height, 1.6) - turn_input * speed / MAX_SPEED * 0.07
	ship_visual.rotation.x = lerp_angle(ship_visual.rotation.x, target_pitch, clampf(delta * 2.5, 0.0, 1.0))
	ship_visual.rotation.z = lerp_angle(ship_visual.rotation.z, target_roll, clampf(delta * 2.5, 0.0, 1.0))

func _update_camera(delta: float) -> void:
	if camera == null or ship == null:
		return
	# Chase camera follows ship heading, keeps the 24m hull clearly visible.
	var follow_offset := ship.global_basis * Vector3(16.0, 16.0, 29.0) * camera_zoom
	var target := ship.global_position + follow_offset
	camera.global_position = camera.global_position.lerp(target, clampf(delta * 3.0, 0, 1))
	camera.look_at(ship.global_position + Vector3(0, 7.0, 0), Vector3.UP)
