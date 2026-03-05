extends Node2D

@export var auto_build := true
@export_range(0.01, 0.25, 0.01) var build_speed := 0.03
@export_range(0.0, 1.0, 0.01) var construction_progress := 0.0

const VIEW_SIZE := Vector2i(1280, 720)
const HORIZON_Y := 290
const SHORE_Y := 450

var _time := 0.0

func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_time += delta

	if auto_build:
		construction_progress = min(1.0, construction_progress + (delta * build_speed))

	if Input.is_action_just_pressed("ui_right"):
		construction_progress = min(1.0, construction_progress + 0.12)
	if Input.is_action_just_pressed("ui_left"):
		construction_progress = max(0.0, construction_progress - 0.12)

	queue_redraw()


func _draw() -> void:
	var p := construction_progress
	_draw_background()
	_draw_water_details(p)
	_draw_messy_start(1.0)
	_draw_shipyard_frame(_fade_in(p, 0.18, 0.45))
	_draw_market_growth(_fade_in(p, 0.42, 0.70))
	_draw_busy_harbor(_fade_in(p, 0.68, 1.0))
	_draw_crane(_fade_in(p, 0.30, 0.85))


func _draw_background() -> void:
	# Sky gradient
	for y in range(HORIZON_Y):
		var t := float(y) / float(HORIZON_Y)
		var sky_color := Color(0.57, 0.78, 0.88).lerp(Color(0.86, 0.90, 0.78), t)
		draw_line(Vector2(0, y), Vector2(VIEW_SIZE.x, y), sky_color, 1.0)

	# Water
	draw_rect(Rect2(0, HORIZON_Y, VIEW_SIZE.x, SHORE_Y - HORIZON_Y), Color(0.14, 0.42, 0.57))
	draw_rect(Rect2(0, SHORE_Y, VIEW_SIZE.x, VIEW_SIZE.y - SHORE_Y), Color(0.44, 0.34, 0.20))

	# Far land silhouette
	draw_rect(Rect2(0, HORIZON_Y - 24, VIEW_SIZE.x, 30), Color(0.24, 0.36, 0.24, 0.8))


func _draw_water_details(progress: float) -> void:
	for i in range(24):
		var y := HORIZON_Y + 10 + i * 7
		var shift := sin((_time * 1.8) + i) * 10.0
		var width := 70 + int(progress * 80.0)
		var x := 40 + int(i * 48 + shift)
		draw_line(Vector2(x, y), Vector2(x + width, y), Color(0.75, 0.91, 0.96, 0.24), 2.0)


func _draw_messy_start(alpha: float) -> void:
	var a: float = clampf(alpha, 0.0, 1.0)

	# Broken temporary dock
	draw_rect(Rect2(170, 390, 320, 28), Color(0.43, 0.26, 0.14, 0.95 * a))
	draw_rect(Rect2(206, 390, 34, 86), Color(0.33, 0.20, 0.10, 0.95 * a))
	draw_rect(Rect2(338, 390, 26, 102), Color(0.33, 0.20, 0.10, 0.95 * a))

	# Scattered crates (messy start)
	_draw_crate(Vector2(120, 462), Vector2(42, 42), a * 0.75)
	_draw_crate(Vector2(168, 470), Vector2(34, 34), a * 0.68)
	_draw_crate(Vector2(498, 458), Vector2(40, 40), a * 0.70)

	# Mud paths
	draw_rect(Rect2(0, 500, 540, 32), Color(0.31, 0.24, 0.15, 0.9 * a))
	draw_rect(Rect2(236, 468, 18, 62), Color(0.30, 0.23, 0.14, 0.9 * a))


func _draw_shipyard_frame(alpha: float) -> void:
	if alpha <= 0.0:
		return

	# Solid pier expansion
	draw_rect(Rect2(460, 368, 300, 38), Color(0.55, 0.34, 0.18, alpha))
	draw_rect(Rect2(518, 368, 20, 136), Color(0.36, 0.21, 0.11, alpha))
	draw_rect(Rect2(642, 368, 20, 146), Color(0.36, 0.21, 0.11, alpha))

	# Hull under construction
	draw_polygon(
		PackedVector2Array([
			Vector2(760, 392),
			Vector2(970, 392),
			Vector2(932, 438),
			Vector2(794, 438)
		]),
		_solid_colors(4, Color(0.45, 0.22, 0.12, alpha))
	)


func _draw_market_growth(alpha: float) -> void:
	if alpha <= 0.0:
		return

	# Warehouses
	draw_rect(Rect2(76, 332, 130, 104), Color(0.66, 0.56, 0.40, alpha))
	draw_rect(Rect2(92, 346, 30, 28), Color(0.31, 0.20, 0.10, alpha))
	draw_rect(Rect2(132, 346, 30, 28), Color(0.31, 0.20, 0.10, alpha))

	draw_rect(Rect2(220, 318, 150, 116), Color(0.64, 0.54, 0.38, alpha))
	draw_rect(Rect2(246, 344, 34, 30), Color(0.30, 0.19, 0.09, alpha))
	draw_rect(Rect2(296, 344, 34, 30), Color(0.30, 0.19, 0.09, alpha))

	# Cleaner roads
	draw_rect(Rect2(0, 528, 760, 26), Color(0.57, 0.50, 0.36, alpha * 0.9))


func _draw_busy_harbor(alpha: float) -> void:
	if alpha <= 0.0:
		return

	# Finished larger ship
	draw_polygon(
		PackedVector2Array([
			Vector2(836, 338),
			Vector2(1174, 338),
			Vector2(1128, 406),
			Vector2(882, 406)
		]),
		_solid_colors(4, Color(0.37, 0.18, 0.10, alpha))
	)

	# Masts + sails
	draw_rect(Rect2(950, 248, 7, 90), Color(0.24, 0.12, 0.06, alpha))
	draw_rect(Rect2(1032, 262, 7, 76), Color(0.24, 0.12, 0.06, alpha))
	draw_polygon(
		PackedVector2Array([
			Vector2(957, 260),
			Vector2(1014, 286),
			Vector2(957, 315)
		]),
		_solid_colors(3, Color(0.90, 0.88, 0.76, alpha))
	)
	draw_polygon(
		PackedVector2Array([
			Vector2(1039, 273),
			Vector2(1080, 292),
			Vector2(1039, 314)
		]),
		_solid_colors(3, Color(0.86, 0.84, 0.72, alpha))
	)

	# Extra piers/trade activity
	draw_rect(Rect2(1020, 410, 180, 24), Color(0.57, 0.34, 0.17, alpha))
	_draw_crate(Vector2(1050, 436), Vector2(34, 34), alpha)
	_draw_crate(Vector2(1090, 438), Vector2(32, 32), alpha)
	_draw_crate(Vector2(1130, 438), Vector2(32, 32), alpha)


func _draw_crane(alpha: float) -> void:
	if alpha <= 0.0:
		return

	var base := Vector2(640, 250)
	var boom_angle := sin(_time * 2.0) * 0.35
	var boom_len := 138.0
	var boom_tip := base + Vector2(cos(boom_angle), sin(boom_angle)) * boom_len
	var hook_drop := 46.0 + sin(_time * 3.5) * 8.0

	draw_rect(Rect2(610, 250, 24, 190), Color(0.66, 0.42, 0.18, alpha))
	draw_line(base, boom_tip, Color(0.75, 0.50, 0.24, alpha), 8.0)
	draw_line(boom_tip, boom_tip + Vector2(0, hook_drop), Color(0.13, 0.12, 0.12, alpha), 3.0)
	draw_rect(Rect2(boom_tip.x - 8, boom_tip.y + hook_drop - 5, 16, 10), Color(0.15, 0.14, 0.14, alpha))


func _fade_in(progress: float, from: float, to: float) -> float:
	if progress <= from:
		return 0.0
	if progress >= to:
		return 1.0
	return (progress - from) / (to - from)


func _solid_colors(count: int, color: Color) -> PackedColorArray:
	var colors := PackedColorArray()
	for i in range(count):
		colors.append(color)
	return colors


func _draw_crate(pos: Vector2, size: Vector2, alpha: float) -> void:
	draw_rect(Rect2(pos, size), Color(0.68, 0.50, 0.26, alpha))
	draw_rect(Rect2(pos + Vector2(4, 4), size - Vector2(8, 8)), Color(0.55, 0.38, 0.18, alpha))
