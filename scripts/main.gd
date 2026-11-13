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
var sea_material: StandardMaterial3D
const TOUCH_HELM = preload("res://scripts/touch_helm.gd")

const MAX_SPEED := 12.0
const ACCEL := 2.2
const TURN_RATE := 0.65

func _ready() -> void:
	_create_world()
	_create_ship()
	_create_camera()
	_create_hud()
	_create_touch_controls()

func _create_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.42, 0.65, 0.74)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.77, 0.85)
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.4
	add_child(sun)
	var sea := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(4000, 4000)
	sea.mesh = mesh
	sea_material = StandardMaterial3D.new()
	sea_material.albedo_color = Color(0.045, 0.27, 0.34)
	sea_material.metallic = 0.1
	sea_material.roughness = 0.32
	sea.material_override = sea_material
	sea.position.y = -0.45
	add_child(sea)

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
	_make_box(ship, Vector3(2.1, 0.8, 5.6), Vector3(0, 0.4, 0), Color(0.35, 0.19, 0.1))
	_make_box(ship, Vector3(1.6, 0.2, 4.4), Vector3(0, 0.85, 0), Color(0.59, 0.39, 0.21))
	_make_box(ship, Vector3(0.14, 4.2, 0.14), Vector3(0, 2.9, -0.45), Color(0.31, 0.18, 0.1))
	_make_box(ship, Vector3(2.3, 2.6, 0.09), Vector3(0, 3.0, -0.45), Color(0.88, 0.84, 0.71))
	_make_box(ship, Vector3(0.13, 2.8, 0.13), Vector3(0, 2.15, 1.6), Color(0.31, 0.18, 0.1))
	_make_box(ship, Vector3(1.6, 1.7, 0.09), Vector3(0, 2.5, 1.6), Color(0.85, 0.8, 0.67))

func _create_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 52.0
	add_child(camera)
	_update_camera(1.0)

func _create_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(24, 22)
	hud.add_theme_font_size_override("font_size", 22)
	layer.add_child(hud)
	var help := Label.new()
	help.text = "A/D or arrows: helm   W/S: sails   Touch: left helm / right sails"
	help.position = Vector2(24, 55)
	help.add_theme_font_size_override("font_size", 15)
	layer.add_child(help)

func _create_touch_controls() -> void:
	var controls := Control.new()
	controls.set_script(TOUCH_HELM)
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	layer.add_child(controls)
	controls.helm_changed.connect(_on_helm_changed)
	controls.sails_changed.connect(_on_sails_changed)

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
	var target_speed := throttle * MAX_SPEED
	speed = move_toward(speed, target_speed, ACCEL * delta)
	ship.rotate_y(-turn_input * TURN_RATE * delta * (0.35 + speed / MAX_SPEED * 0.65))
	ship.translate_object_local(Vector3(0, 0, -speed * delta))
	hud.text = "OCEAN LORDS ONLINE  |  %.1f kn  |  Sails %d%%" % [speed, roundi(throttle * 100)]
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	if camera == null or ship == null:
		return
	var target := ship.global_position + Vector3(0, 24, 29)
	camera.global_position = camera.global_position.lerp(target, clampf(delta * 3.0, 0, 1))
	camera.look_at(ship.global_position + Vector3(0, 1.5, 0), Vector3.UP)
