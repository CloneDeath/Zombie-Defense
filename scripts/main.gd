extends Control

const ZOMBIE_TEXTURE := preload("res://assets/kenney/zombie.png")
const SURVIVOR_TEXTURE := preload("res://assets/kenney/survivor.png")
const STARTING_HEALTH := 10
const ZOMBIE_SPEED := 0.16
const ZOMBIE_MAX_HEALTH := 3
const FIRE_RATE := 0.65
const SURVIVOR_SPEED := 120.0
const MAP_WIDTH_METERS := 12.0
const SURVIVOR_RANGE_METERS := 3.0

var screen := "menu"
var health := STARTING_HEALTH
var zombies_passed := 0
var zombies_killed := 0
var zombie_x := -0.1
var zombie_health := ZOMBIE_MAX_HEALTH
var spawn_delay := 0.6
var zombie_active := false

var survivor_spawn := -1
var survivor_selected := false
var dragging_survivor := false
var drag_position := Vector2.ZERO
var fire_cooldown := 0.0
var survivor_position := Vector2.ZERO
var survivor_target := Vector2.ZERO
var survivor_is_walking := false
var shots: Array[Dictionary] = []

var title_label: Label
var health_label: Label
var results_label: Label
var version_label: Label
var begin_button: Button
var retry_button: Button
var menu_button: Button

func _ready() -> void:
	title_label = _make_label(38, Color.WHITE)
	title_label.text = "ZOMBIE DEFENSE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	health_label = _make_label(24, Color("#f5e8c8"))
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	results_label = _make_label(24, Color.WHITE)
	results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	version_label = _make_label(12, Color("#a8b5a5"))
	version_label.text = "%s • %s" % [BuildVersion.BRANCH, BuildVersion.COMMIT]
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	begin_button = _make_button("BEGIN")
	begin_button.pressed.connect(_start_game)
	retry_button = _make_button("RETRY")
	retry_button.pressed.connect(_start_game)
	menu_button = _make_button("BACK TO MENU")
	menu_button.pressed.connect(_show_menu)

	_show_menu()
	_layout_ui()

func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _make_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.add_theme_font_size_override("font_size", 20)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#4f7655")
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color("#65976d")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	add_child(button)
	return button

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout_ui()
		queue_redraw()

func _layout_ui() -> void:
	var center_x := size.x * 0.5
	var portrait := size.y > size.x
	title_label.position = Vector2(10, size.y * (0.22 if portrait else 0.18))
	title_label.size = Vector2(size.x - 20, 55)
	title_label.add_theme_font_size_override("font_size", 32 if portrait else 38)

	version_label.position = Vector2(size.x - 225, 8)
	version_label.size = Vector2(210, 22)

	health_label.position = Vector2(10, 45)
	health_label.size = Vector2(size.x - 20, 40)
	health_label.add_theme_font_size_override("font_size", 20 if portrait else 24)

	results_label.position = Vector2(10, size.y * (0.38 if portrait else 0.36))
	results_label.size = Vector2(size.x - 20, 76)

	begin_button.position = Vector2(center_x - 100, size.y * 0.52)
	begin_button.size = Vector2(200, 58)

	if portrait:
		retry_button.position = Vector2(center_x - 100, size.y * 0.56)
		retry_button.size = Vector2(200, 58)
		menu_button.position = Vector2(center_x - 100, size.y * 0.56 + 70)
		menu_button.size = Vector2(200, 58)
	else:
		retry_button.position = Vector2(center_x - 155, size.y * 0.58)
		retry_button.size = Vector2(145, 58)
		menu_button.position = Vector2(center_x + 10, size.y * 0.58)
		menu_button.size = Vector2(145, 58)

func _process(delta: float) -> void:
	if screen != "playing":
		return

	if zombie_active:
		zombie_x += ZOMBIE_SPEED * delta
		if survivor_spawn >= 0:
			survivor_target = _spawn_points()[survivor_spawn]
			var zombie_in_range := survivor_position.distance_to(_zombie_position()) <= _survivor_range()
			if zombie_in_range:
				survivor_is_walking = false
				fire_cooldown -= delta
				if fire_cooldown <= 0.0:
					_shoot()
			elif survivor_position.distance_to(survivor_target) > 1.0:
				survivor_is_walking = true
				survivor_position = survivor_position.move_toward(survivor_target, SURVIVOR_SPEED * delta)
			else:
				survivor_is_walking = false
		if zombie_x > 1.08:
			zombie_active = false
			zombies_passed += 1
			health -= 1
			if health <= 0:
				_show_results()
			else:
				spawn_delay = 0.55
	else:
		spawn_delay -= delta
		if spawn_delay <= 0.0:
			_spawn_zombie()

	for shot in shots.duplicate():
		shot.life -= delta
		if shot.life <= 0.0:
			shots.erase(shot)

	health_label.text = "TOWN HEALTH: %d    KILLED: %d" % [health, zombies_killed]
	queue_redraw()

func _spawn_zombie() -> void:
	zombie_x = -0.1
	zombie_health = ZOMBIE_MAX_HEALTH
	zombie_active = true
	fire_cooldown = 0.15

func _shoot() -> void:
	var points := _spawn_points()
	var start := survivor_position
	var target := _zombie_position()
	shots.append({"start":start, "end":target, "life":0.12})
	fire_cooldown = FIRE_RATE
	zombie_health -= 1
	if zombie_health <= 0:
		zombie_active = false
		zombies_killed += 1
		spawn_delay = 0.6

func _start_game() -> void:
	screen = "playing"
	health = STARTING_HEALTH
	zombies_passed = 0
	zombies_killed = 0
	zombie_x = -0.1
	spawn_delay = 0.5
	zombie_active = false
	survivor_spawn = -1
	survivor_selected = false
	dragging_survivor = false
	fire_cooldown = 0.0
	shots.clear()
	title_label.hide()
	results_label.hide()
	begin_button.hide()
	retry_button.hide()
	menu_button.hide()
	health_label.show()
	health_label.text = "TOWN HEALTH: %d    KILLED: 0" % health
	queue_redraw()

func _show_menu() -> void:
	screen = "menu"
	title_label.text = "ZOMBIE DEFENSE"
	title_label.show()
	health_label.hide()
	results_label.hide()
	begin_button.show()
	retry_button.hide()
	menu_button.hide()
	queue_redraw()

func _show_results() -> void:
	screen = "results"
	zombie_active = false
	health_label.hide()
	title_label.show()
	title_label.text = "THE TOWN FELL"
	results_label.text = "%d zombies killed\n%d zombies got through" % [zombies_killed, zombies_passed]
	results_label.show()
	begin_button.hide()
	retry_button.show()
	menu_button.show()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if screen != "playing" or survivor_spawn >= 0:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_pointer_down(event.position)
		else:
			_handle_pointer_up(event.position)
	elif event is InputEventScreenDrag:
		if dragging_survivor:
			drag_position = event.position
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_pointer_down(event.position)
		else:
			_handle_pointer_up(event.position)
	elif event is InputEventMouseMotion and dragging_survivor:
		drag_position = event.position
		queue_redraw()

func _handle_pointer_down(position: Vector2) -> void:
	if _survivor_card_rect().has_point(position):
		survivor_selected = true
		dragging_survivor = true
		drag_position = position
		queue_redraw()
	elif survivor_selected:
		var index := _spawn_point_at(position)
		if index >= 0:
			_place_survivor(index)

func _handle_pointer_up(position: Vector2) -> void:
	if not dragging_survivor:
		return
	dragging_survivor = false
	var index := _spawn_point_at(position)
	if index >= 0:
		_place_survivor(index)
	queue_redraw()

func _place_survivor(index: int) -> void:
	survivor_spawn = index
	survivor_target = _spawn_points()[index]
	survivor_position = Vector2(size.x + 55.0, survivor_target.y)
	survivor_is_walking = true
	survivor_selected = false
	dragging_survivor = false
	fire_cooldown = 0.0
	queue_redraw()

func _spawn_point_at(position: Vector2) -> int:
	var points := _spawn_points()
	for i in points.size():
		if points[i].distance_to(position) <= 38.0:
			return i
	return -1

func _field_rect() -> Rect2:
	return Rect2(0, 90, size.x, maxf(160.0, size.y - 205.0))

func _road_rect() -> Rect2:
	var field := _field_rect()
	var road_height := minf(135.0, field.size.y * 0.48)
	return Rect2(0, field.position.y + (field.size.y - road_height) * 0.5, size.x, road_height)

func _spawn_points() -> Array[Vector2]:
	var road := _road_rect()
	var upper_y := maxf(_field_rect().position.y + 32.0, road.position.y - 34.0)
	var lower_y := minf(_field_rect().end.y - 32.0, road.end.y + 34.0)
	return [
		Vector2(size.x * 0.35, upper_y),
		Vector2(size.x * 0.65, upper_y),
		Vector2(size.x * 0.35, lower_y),
		Vector2(size.x * 0.65, lower_y)
	]

func _survivor_card_rect() -> Rect2:
	return Rect2(size.x * 0.5 - 52, size.y - 105, 104, 92)

func _zombie_position() -> Vector2:
	var road := _road_rect()
	return Vector2(zombie_x * size.x, road.position.y + road.size.y * 0.5)

func _survivor_range() -> float:
	return size.x / MAP_WIDTH_METERS * SURVIVOR_RANGE_METERS

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#111812"))

	if screen != "playing":
		return

	var field := _field_rect()
	var road := _road_rect()
	draw_rect(field, Color("#334a35"))
	draw_rect(road, Color("#5b5a50"))
	draw_line(Vector2(0, road.position.y), Vector2(size.x, road.position.y), Color("#7b795f"), 4)
	draw_line(Vector2(0, road.end.y), Vector2(size.x, road.end.y), Color("#7b795f"), 4)

	var points := _spawn_points()
	for i in points.size():
		var occupied := i == survivor_spawn
		var point_color := Color("#d9ba58") if survivor_selected and not occupied else Color("#78917a")
		draw_circle(points[i], 30, Color(point_color, 0.35))
		draw_arc(points[i], 30, 0, TAU, 32, point_color, 3)
		if not occupied:
			draw_string(ThemeDB.fallback_font, points[i] + Vector2(-7, 7), "+", HORIZONTAL_ALIGNMENT_CENTER, 14, 22, point_color)

	if survivor_spawn >= 0:
		draw_circle(survivor_position, _survivor_range(), Color(0.45, 0.72, 0.48, 0.08))
		draw_arc(survivor_position, _survivor_range(), 0, TAU, 48, Color(0.45, 0.72, 0.48, 0.25), 2)

		var aim_angle := 0.0
		if zombie_active and survivor_position.distance_to(_zombie_position()) <= _survivor_range():
			aim_angle = survivor_position.angle_to_point(_zombie_position())
		elif survivor_is_walking:
			aim_angle = survivor_position.angle_to_point(survivor_target)

		draw_set_transform(survivor_position, aim_angle)
		draw_texture_rect(
			SURVIVOR_TEXTURE,
			Rect2(Vector2(-38, -32), Vector2(76, 64)),
			false
		)
		draw_set_transform(Vector2.ZERO, 0.0)

	if zombie_active:
		var zombie_position := _zombie_position()
		draw_texture_rect(
			ZOMBIE_TEXTURE,
			Rect2(zombie_position - Vector2(30, 39), Vector2(60, 78)),
			false
		)
		var bar_position := zombie_position + Vector2(-25, -47)
		draw_rect(Rect2(bar_position, Vector2(50, 6)), Color("#251f1f"))
		draw_rect(Rect2(bar_position, Vector2(50.0 * zombie_health / ZOMBIE_MAX_HEALTH, 6)), Color("#d85a55"))

	for shot in shots:
		draw_line(shot.start, shot.end, Color("#ffe184"), 3)
		draw_circle(shot.end, 4, Color("#fff4b0"))

	if survivor_spawn < 0:
		var card := _survivor_card_rect()
		var card_color := Color("#6f8e70") if survivor_selected else Color("#344d38")
		draw_rect(card, card_color)
		draw_rect(card, Color("#9fba9e"), false, 2)
		draw_texture_rect(SURVIVOR_TEXTURE, Rect2(card.position + Vector2(23, 5), Vector2(58, 49)), false)
		draw_string(ThemeDB.fallback_font, card.position + Vector2(10, 78), "SURVIVOR • 3m", HORIZONTAL_ALIGNMENT_CENTER, 84, 13, Color.WHITE)

	if dragging_survivor:
		draw_texture_rect(
			SURVIVOR_TEXTURE,
			Rect2(drag_position - Vector2(38, 32), Vector2(76, 64)),
			false,
			Color(1, 1, 1, 0.75)
	)
