extends Node2D

const DAY_LENGTH := 2.5
const TIER_NAMES := ["Messy Harbor", "Growing Shipyard", "Trade District", "Prosperous Port"]

var day := 1
var tier := 0

var gold := 120
var wood := 28
var iron := 10
var cloth := 12

var ships_built := 0
var queued_ships := 1
var trade_route_enabled := true
var last_daily_profit := 0

var _day_timer := 0.0
var _time := 0.0
var _rng := RandomNumberGenerator.new()

@onready var day_label: Label = $CanvasLayer/UI/LeftPanel/DayLabel
@onready var tier_label: Label = $CanvasLayer/UI/LeftPanel/TierLabel
@onready var gold_label: Label = $CanvasLayer/UI/LeftPanel/GoldLabel
@onready var resources_label: Label = $CanvasLayer/UI/LeftPanel/ResourcesLabel
@onready var fleet_label: Label = $CanvasLayer/UI/LeftPanel/FleetLabel
@onready var profit_label: Label = $CanvasLayer/UI/LeftPanel/ProfitLabel
@onready var route_label: Label = $CanvasLayer/UI/LeftPanel/RouteLabel
@onready var queue_label: Label = $CanvasLayer/UI/LeftPanel/QueueLabel
@onready var tier_hint_label: Label = $CanvasLayer/UI/RightPanel/TierHintLabel

@onready var queue_ship_button: Button = $CanvasLayer/UI/LeftPanel/QueueShipButton
@onready var route_button: Button = $CanvasLayer/UI/LeftPanel/RouteButton

@onready var messy_group: Node2D = $World/MessyGroup
@onready var developing_group: Node2D = $World/DevelopingGroup
@onready var market_group: Node2D = $World/MarketGroup
@onready var prosperous_group: Node2D = $World/ProsperousGroup
@onready var base_ship: Sprite2D = $World/BaseShip
@onready var crane: Sprite2D = $World/DevelopingGroup/Crane


func _ready() -> void:
	_rng.randomize()
	queue_ship_button.pressed.connect(_on_queue_ship_pressed)
	route_button.pressed.connect(_on_toggle_route_pressed)
	_apply_tier_visuals()
	_update_ui()
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_day_timer += delta
	_animate_world()

	if _day_timer >= DAY_LENGTH:
		_day_timer -= DAY_LENGTH
		_simulate_day()

	if Input.is_action_just_pressed("ui_accept"):
		_on_queue_ship_pressed()
	if Input.is_action_just_pressed("ui_right"):
		_set_debug_tier(tier + 1)
	if Input.is_action_just_pressed("ui_left"):
		_set_debug_tier(tier - 1)

	queue_redraw()


func _draw() -> void:
	# Sky + sea + shore painterly base to support sprite layers.
	for y in range(0, 280):
		var t := float(y) / 280.0
		var sky := Color(0.53, 0.76, 0.90).lerp(Color(0.87, 0.92, 0.83), t)
		draw_line(Vector2(0, y), Vector2(1280, y), sky, 1.0)

	draw_rect(Rect2(0, 280, 1280, 210), Color(0.17, 0.46, 0.63))
	draw_rect(Rect2(0, 490, 1280, 230), Color(0.44, 0.34, 0.21))

	# Wooden piers evolve with tier.
	draw_rect(Rect2(120, 402, 350, 34), Color(0.53, 0.31, 0.16))
	if tier >= 1:
		draw_rect(Rect2(490, 382, 300, 36), Color(0.57, 0.34, 0.17))
	if tier >= 2:
		draw_rect(Rect2(810, 398, 300, 30), Color(0.60, 0.36, 0.18))

	# Water shimmer intensity grows with development.
	for i in range(18):
		var wobble := sin(_time * 2.0 + i * 0.7) * 12.0
		var width := 55 + (tier * 18)
		var x := 40 + i * 68 + int(wobble)
		var y := 304 + i * 9
		draw_line(Vector2(x, y), Vector2(x + width, y), Color(0.77, 0.92, 0.98, 0.24), 2.0)


func _animate_world() -> void:
	crane.frame = int(floor(_time * 8.0)) % 16
	base_ship.position.y = 360.0 + sin(_time * 1.6) * 3.5
	$World/MarketGroup/ShipMedium.position.y = 344.0 + sin(_time * 1.2) * 2.5
	$World/ProsperousGroup/ShipLarge.position.y = 330.0 + sin(_time * 0.95) * 3.0


func _simulate_day() -> void:
	day += 1

	var wood_income := 7 + tier * 4 + (2 if trade_route_enabled else 0)
	var iron_income := 2 + tier + (1 if trade_route_enabled else 0)
	var cloth_income := 3 + tier * 2

	wood += wood_income
	iron += iron_income
	cloth += cloth_income

	var built_today := 0
	while queued_ships > 0 and wood >= 20 and iron >= 6 and cloth >= 8:
		queued_ships -= 1
		wood -= 20
		iron -= 6
		cloth -= 8
		ships_built += 1
		built_today += 1

	var route_multiplier := 1.0 if trade_route_enabled else 0.6
	var trade_income := int(ships_built * (26 + tier * 14) * route_multiplier)
	var upkeep := 14 + tier * 8 + ships_built * 2
	var market_noise := _rng.randi_range(-10, 16)

	last_daily_profit = trade_income + market_noise - upkeep - built_today * 6
	gold = max(0, gold + last_daily_profit)

	_check_tier_progression()
	_apply_tier_visuals()
	_update_ui()


func _check_tier_progression() -> void:
	var new_tier := tier
	if gold >= 350 and ships_built >= 1:
		new_tier = max(new_tier, 1)
	if gold >= 1100 and ships_built >= 3:
		new_tier = max(new_tier, 2)
	if gold >= 2600 and ships_built >= 6:
		new_tier = max(new_tier, 3)
	tier = clamp(new_tier, 0, 3)


func _apply_tier_visuals() -> void:
	messy_group.visible = true
	developing_group.visible = tier >= 1
	market_group.visible = tier >= 2
	prosperous_group.visible = tier >= 3

	$World/MessyGroup/ConstructionHull.visible = ships_built == 0
	$World/DevelopingGroup/DockShip.visible = ships_built >= 1
	$World/MarketGroup/ShipMedium.visible = ships_built >= 3
	$World/ProsperousGroup/ShipLarge.visible = ships_built >= 6
	$World/ProsperousGroup/EscortShip.visible = ships_built >= 4

	base_ship.modulate = Color(1, 1, 1, 0.72 + (tier * 0.08))


func _update_ui() -> void:
	day_label.text = "Day: %d" % day
	tier_label.text = "Tier: %s" % TIER_NAMES[tier]
	gold_label.text = "Gold: %d" % gold
	resources_label.text = "Wood %d | Iron %d | Cloth %d" % [wood, iron, cloth]
	fleet_label.text = "Fleet: %d ships" % ships_built
	profit_label.text = "Daily Profit: %d" % last_daily_profit
	route_label.text = "Route: %s" % ("Active" if trade_route_enabled else "Paused")
	queue_label.text = "Ship Queue: %d" % queued_ships

	tier_hint_label.text = _tier_goal_text()
	route_button.text = "Pause Route" if trade_route_enabled else "Resume Route"


func _tier_goal_text() -> String:
	if tier == 0:
		return "Next Tier: Reach 350 gold and build 1 ship."
	if tier == 1:
		return "Next Tier: Reach 1100 gold and build 3 ships."
	if tier == 2:
		return "Next Tier: Reach 2600 gold and build 6 ships."
	return "Top tier reached. Focus on fleet efficiency and profit."


func _on_queue_ship_pressed() -> void:
	queued_ships += 1
	_update_ui()


func _on_toggle_route_pressed() -> void:
	trade_route_enabled = not trade_route_enabled
	_update_ui()


func _set_debug_tier(value: int) -> void:
	tier = clamp(value, 0, 3)
	_apply_tier_visuals()
	_update_ui()
