extends Node2D
## Moonlit Lake — Procedural pixel art demo.
## No external assets needed. Everything is generated through code.

# === VIEWPORT ===
const W := 320
const H := 180
const WATER_Y := 118

# === CONFIG ===
const MOON_POS := Vector2(250.0, 30.0)
const MOON_R := 9.0
const NUM_STARS := 100
const NUM_FIREFLIES := 12

# === PALETTE ===
# Sky
const C_SKY_TOP     := Color(0.03, 0.01, 0.08)
const C_SKY_MID     := Color(0.06, 0.03, 0.15)
const C_SKY_LOW     := Color(0.10, 0.05, 0.20)
const C_SKY_HORIZON := Color(0.15, 0.08, 0.22)
# Celestial
const C_MOON      := Color(0.95, 0.93, 0.82)
const C_MOON_GLOW := Color(0.60, 0.50, 0.75)
const C_STAR      := Color(0.90, 0.87, 0.95)
# Mountains
const C_MT_FAR  := Color(0.07, 0.04, 0.16)
const C_MT_MID  := Color(0.05, 0.03, 0.12)
const C_MT_NEAR := Color(0.04, 0.02, 0.09)
# Ground
const C_GROUND  := Color(0.03, 0.07, 0.04)
const C_GRASS_A := Color(0.04, 0.12, 0.05)
const C_GRASS_B := Color(0.02, 0.08, 0.03)
# Trees
const C_TREE_DARK  := Color(0.02, 0.05, 0.03)
const C_TREE_MID   := Color(0.03, 0.09, 0.05)
const C_TREE_LIGHT := Color(0.05, 0.13, 0.07)
const C_TRUNK      := Color(0.08, 0.05, 0.03)
# Water
const C_WATER_DEEP  := Color(0.02, 0.03, 0.08)
const C_WATER_SHINE := Color(0.12, 0.14, 0.30)
# Fireflies
const C_FIREFLY      := Color(0.90, 0.95, 0.30)
const C_FIREFLY_GLOW := Color(0.45, 0.50, 0.15)
# Flowers
const C_FLOWER_R := Color(0.55, 0.12, 0.15)
const C_FLOWER_B := Color(0.15, 0.12, 0.55)
const C_FLOWER_Y := Color(0.70, 0.65, 0.15)

# === STATE ===
var time := 0.0
var stars: Array = []
var fireflies: Array = []
var bg_texture: ImageTexture
var rng := RandomNumberGenerator.new()


# =========================================================================
#  LIFECYCLE
# =========================================================================

func _ready() -> void:
	rng.seed = 42
	_init_stars()
	_init_fireflies()
	bg_texture = _render_background()


func _process(delta: float) -> void:
	time += delta
	_update_fireflies(delta)
	queue_redraw()


func _draw() -> void:
	# Layer 0 — static pre-rendered background
	draw_texture(bg_texture, Vector2.ZERO)
	# Layer 1 — animated sky elements
	_draw_stars()
	_draw_moon_glow()
	# Layer 2 — animated water
	_draw_water_ripples()
	_draw_moon_reflection()
	_draw_water_sparkles()
	# Layer 3 — creatures
	_draw_fireflies()


# =========================================================================
#  INITIALIZATION
# =========================================================================

func _init_stars() -> void:
	for i in NUM_STARS:
		stars.append({
			"x": rng.randf_range(0, W),
			"y": rng.randf_range(2, 62),
			"phase": rng.randf_range(0, TAU),
			"speed": rng.randf_range(0.5, 2.5),
			"brightness": rng.randf_range(0.3, 1.0),
		})


func _init_fireflies() -> void:
	for i in NUM_FIREFLIES:
		var bx := rng.randf_range(20, W - 20)
		var by := rng.randf_range(WATER_Y - 45, WATER_Y - 5)
		fireflies.append({
			"x": bx, "y": by,
			"base_x": bx, "base_y": by,
			"phase": rng.randf_range(0, TAU),
			"speed": rng.randf_range(0.3, 0.8),
			"glow_phase": rng.randf_range(0, TAU),
			"glow_speed": rng.randf_range(0.5, 1.5),
		})


func _update_fireflies(delta: float) -> void:
	for f in fireflies:
		f.phase += f.speed * delta
		f.x = f.base_x + sin(f.phase) * 15.0 + sin(f.phase * 0.7) * 8.0
		f.y = f.base_y + cos(f.phase * 0.6) * 8.0 + sin(f.phase * 1.3) * 4.0
		f.glow_phase += f.glow_speed * delta


# =========================================================================
#  STATIC BACKGROUND  (generated once in _ready)
# =========================================================================

func _render_background() -> ImageTexture:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	_paint_sky(img)
	_paint_moon(img)
	_paint_mountains(img)
	_paint_ground(img)
	_paint_trees(img)
	_paint_flowers(img)
	_paint_water_base(img)
	return ImageTexture.create_from_image(img)


func _paint_sky(img: Image) -> void:
	for y in range(WATER_Y):
		var t := float(y) / float(WATER_Y)
		var color: Color
		if t < 0.3:
			color = C_SKY_TOP.lerp(C_SKY_MID, t / 0.3)
		elif t < 0.7:
			color = C_SKY_MID.lerp(C_SKY_LOW, (t - 0.3) / 0.4)
		else:
			color = C_SKY_LOW.lerp(C_SKY_HORIZON, (t - 0.7) / 0.3)
		for x in range(W):
			img.set_pixel(x, y, color)


func _paint_moon(img: Image) -> void:
	var cx := int(MOON_POS.x)
	var cy := int(MOON_POS.y)
	var r := int(MOON_R)
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var dist_sq := dx * dx + dy * dy
			if dist_sq > r * r:
				continue
			var px := cx + dx
			var py := cy + dy
			if px < 0 or px >= W or py < 0 or py >= H:
				continue
			var dist := sqrt(float(dist_sq)) / float(r)
			var shade := 1.0 - dist * 0.12
			var crater := sin(dx * 0.8) * cos(dy * 0.7) * 0.06
			img.set_pixel(px, py, Color(
				C_MOON.r * shade - crater,
				C_MOON.g * shade - crater * 0.5,
				C_MOON.b * shade,
				1.0
			))


func _paint_mountains(img: Image) -> void:
	_paint_mt_layer(img, C_MT_FAR, 72, 24.0, 0.02, 0.05, 0.0)
	_paint_mt_layer(img, C_MT_MID, 82, 20.0, 0.03, 0.04, 100.0)
	_paint_mt_layer(img, C_MT_NEAR, 92, 16.0, 0.04, 0.06, 200.0)


func _paint_mt_layer(img: Image, color: Color, base_y: int, amp: float,
		f1: float, f2: float, offset: float) -> void:
	for x in range(W):
		var xf := float(x) + offset
		var h := sin(xf * f1) * amp
		h += sin(xf * f2 + 1.5) * amp * 0.5
		h += sin(xf * f1 * 3.7 + 2.8) * amp * 0.25
		var peak_y := base_y - int(h)
		for y in range(max(0, peak_y), WATER_Y):
			var grad := float(y - peak_y) / max(1.0, float(WATER_Y - peak_y))
			img.set_pixel(x, y, color.darkened(grad * 0.1))


func _paint_ground(img: Image) -> void:
	for y in range(WATER_Y - 6, WATER_Y):
		var t := float(y - (WATER_Y - 6)) / 6.0
		for x in range(W):
			var c := C_MT_NEAR.lerp(C_GROUND, t)
			if y >= WATER_Y - 3:
				var noise := sin(x * 0.5) * cos(x * 1.3)
				if noise > 0.3:
					c = c.lerp(C_GRASS_A, 0.5)
				elif noise < -0.3:
					c = c.lerp(C_GRASS_B, 0.3)
			img.set_pixel(x, y, c)


func _paint_trees(img: Image) -> void:
	var positions := [
		15, 35, 42, 68, 85, 95, 120, 145, 158,
		180, 195, 210, 230, 265, 278, 295, 305,
	]
	for tx in positions:
		var h := 10 + int(abs(sin(tx * 0.3)) * 8)
		_paint_pine(img, tx, WATER_Y - 2, h)


func _paint_pine(img: Image, bx: int, by: int, height: int) -> void:
	# Trunk
	for y in range(by - 2, by + 1):
		_px(img, bx, y, C_TRUNK)
	# Layered foliage
	var layers := 3
	var layer_h := height / layers
	for layer in range(layers):
		var ly := by - 3 - layer * layer_h
		var max_w := (layers - layer) * 2 + 1
		for dy in range(layer_h + 1):
			var row_y := ly - dy
			var w := max(1, max_w - int(dy * 0.8))
			for dx in range(-w, w + 1):
				var c: Color
				if dx < -1:
					c = C_TREE_DARK
				elif dx > 1:
					c = C_TREE_LIGHT   # moonlit side
				else:
					c = C_TREE_MID
				_px(img, bx + dx, row_y, c)
	# Treetop highlight
	_px(img, bx, by - 3 - height + 2, C_TREE_LIGHT)


func _paint_flowers(img: Image) -> void:
	var colors := [C_FLOWER_R, C_FLOWER_B, C_FLOWER_Y]
	for i in range(12):
		var fx := rng.randi_range(10, W - 10)
		var fy := rng.randi_range(WATER_Y - 4, WATER_Y - 1)
		_px(img, fx, fy, colors[i % 3])


func _paint_water_base(img: Image) -> void:
	# Reflect the above-water scene, darkened, to create water
	for y in range(WATER_Y, H):
		var reflect_y := WATER_Y - (y - WATER_Y) - 1
		var depth := float(y - WATER_Y) / float(H - WATER_Y)
		for x in range(W):
			if reflect_y >= 0 and reflect_y < H:
				var src := img.get_pixel(x, reflect_y)
				var reflected := src.darkened(0.55 + depth * 0.25)
				reflected = reflected.lerp(C_WATER_DEEP, depth * 0.5)
				img.set_pixel(x, y, reflected)
			else:
				img.set_pixel(x, y, C_WATER_DEEP)


# =========================================================================
#  ANIMATED DRAWING  (called every frame from _draw)
# =========================================================================

func _draw_stars() -> void:
	for s in stars:
		var twinkle := sin(time * s.speed + s.phase) * 0.5 + 0.5
		var alpha := s.brightness * twinkle
		if alpha > 0.1:
			draw_rect(
				Rect2(s.x, s.y, 1, 1),
				Color(C_STAR.r, C_STAR.g, C_STAR.b, alpha)
			)


func _draw_moon_glow() -> void:
	var pulse := sin(time * 0.4) * 0.08 + 1.0
	for i in range(6, 0, -1):
		var radius := MOON_R + float(i) * 5.0 * pulse
		var alpha := 0.03 / float(i) * pulse
		draw_circle(
			MOON_POS, radius,
			Color(C_MOON_GLOW.r, C_MOON_GLOW.g, C_MOON_GLOW.b, alpha)
		)


func _draw_water_ripples() -> void:
	for y in range(WATER_Y, H):
		var depth := float(y - WATER_Y) / float(H - WATER_Y)
		var ripple := sin(float(y) * 1.5 + time * 1.2) * 0.5 + 0.5
		if ripple > 0.82:
			var alpha := (ripple - 0.82) / 0.18 * 0.1 * (1.0 - depth * 0.5)
			draw_line(
				Vector2(0, y), Vector2(W, y),
				Color(C_WATER_SHINE.r, C_WATER_SHINE.g, C_WATER_SHINE.b, alpha)
			)


func _draw_moon_reflection() -> void:
	for y in range(WATER_Y + 2, H - 1):
		var depth := float(y - WATER_Y) / float(H - WATER_Y)
		var wave := sin(float(y) * 0.3 + time * 1.5) * (2.0 + depth * 5.0)
		var rx := MOON_POS.x + wave
		var width := 1.0 + depth * 3.0
		var alpha := (0.35 - depth * 0.3) * (sin(float(y) * 0.8 + time * 2.0) * 0.3 + 0.7)
		if alpha > 0.03:
			draw_line(
				Vector2(rx - width, y), Vector2(rx + width, y),
				Color(C_MOON.r, C_MOON.g, C_MOON.b, alpha * 0.6)
			)


func _draw_water_sparkles() -> void:
	for i in range(30):
		var seed_v := float(i) * 7.31
		var sx := fmod(seed_v * 43.37, float(W))
		var sy := float(WATER_Y) + fmod(seed_v * 17.83, float(H - WATER_Y))
		var sparkle := sin(time * 1.5 + seed_v) * 0.5 + 0.5
		if sparkle > 0.9:
			var alpha := (sparkle - 0.9) / 0.1 * 0.35
			draw_rect(Rect2(sx, sy, 1, 1), Color(0.5, 0.5, 0.7, alpha))


func _draw_fireflies() -> void:
	for f in fireflies:
		var glow := sin(f.glow_phase) * 0.5 + 0.5
		if glow > 0.15:
			# Soft outer glow
			draw_circle(
				Vector2(f.x, f.y), 3.0,
				Color(C_FIREFLY_GLOW.r, C_FIREFLY_GLOW.g, C_FIREFLY_GLOW.b, glow * 0.12)
			)
			# Bright core pixel
			draw_rect(
				Rect2(f.x, f.y, 1, 1),
				Color(C_FIREFLY.r, C_FIREFLY.g, C_FIREFLY.b, glow * 0.9)
			)


# =========================================================================
#  UTILITY
# =========================================================================

func _px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < W and y >= 0 and y < H:
		img.set_pixel(x, y, color)
