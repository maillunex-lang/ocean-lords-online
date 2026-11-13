extends Control
## Minimal multitouch helm for landscape Android. Draws inside viewport with conservative margins.
signal helm_changed(value: float)
signal sails_changed(value: float)

var helm_finger: int = -1
var sail_finger: int = -1
var helm_value: float = 0.0
var sail_value: float = 0.0
var sail_fraction: float = 0.7
var _safe_pad: float = 58.0
const RADIUS := 66.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _helm_center() -> Vector2:
	return Vector2(_safe_pad + RADIUS, size.y - _safe_pad - RADIUS)

func _sail_center() -> Vector2:
	return Vector2(size.x - _safe_pad - 44.0, size.y - _safe_pad - 82.0)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var p := event.position
		if event.pressed:
			if helm_finger == -1 and p.x < size.x * 0.42 and p.y > size.y * 0.42:
				helm_finger = event.index
				_set_helm(p)
			elif sail_finger == -1 and p.x > size.x * 0.58 and p.y > size.y * 0.4:
				sail_finger = event.index
				_set_sail(p)
		else:
			if event.index == helm_finger:
				helm_finger = -1
				helm_value = 0.0
				helm_changed.emit(0.0)
				queue_redraw()
			if event.index == sail_finger:
				sail_finger = -1
	elif event is InputEventScreenDrag:
		if event.index == helm_finger:
			_set_helm(event.position)
		elif event.index == sail_finger:
			_set_sail(event.position)

func _set_helm(p: Vector2) -> void:
	helm_value = clampf((p.x - _helm_center().x) / RADIUS, -1.0, 1.0)
	helm_changed.emit(helm_value)
	queue_redraw()

func _set_sail(p: Vector2) -> void:
	sail_fraction = clampf(1.0 - (p.y - (_sail_center().y - 100.0)) / 200.0, 0.0, 1.0)
	sails_changed.emit(sail_fraction)
	queue_redraw()

func _draw() -> void:
	var helm := _helm_center()
	draw_circle(helm, RADIUS, Color(0.06, 0.16, 0.22, 0.55))
	draw_arc(helm, RADIUS, 0.0, TAU, 48, Color(0.56, 0.82, 0.88, 0.8), 3.0)
	draw_circle(helm + Vector2(helm_value * RADIUS * 0.72, 0), 24.0, Color(0.69, 0.85, 0.88, 0.8))
	var c := _sail_center()
	draw_rect(Rect2(c.x - 15, c.y - 100, 30, 200), Color(0.06, 0.16, 0.22, 0.6), true)
	draw_rect(Rect2(c.x - 15, c.y + 100 - 200 * sail_fraction, 30, 200 * sail_fraction), Color(0.31, 0.7, 0.56, 0.85), true)
	draw_circle(Vector2(c.x, c.y + 100 - 200 * sail_fraction), 22, Color(0.88, 0.83, 0.66, 0.95))
