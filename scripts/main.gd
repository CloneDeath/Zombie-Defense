extends Control

const ZOMBIE_TEXTURE := preload("res://assets/kenney/zombie.png")
const SURVIVOR_TEXTURE := preload("res://assets/kenney/survivor.png")
const STARTING_HEALTH := 10
const ZOMBIE_SPEED := 0.10
const ZOMBIE_CHASE_SPEED := 55.0
const ZOMBIE_ATTACK_RANGE := 34.0
const ZOMBIE_ATTACK_RATE := 0.8
const SURVIVOR_MAX_HEALTH := 10
const ZOMBIE_MAX_HEALTH := 3
const FIRE_RATE := 0.65
const SURVIVOR_SPEED := 120.0
const MAP_WIDTH_METERS := 12.0
const SURVIVOR_RANGE_METERS := 3.0
const SURVIVOR_AWARENESS_MULTIPLIER := 2.0
const SURVIVOR_TURN_SPEED := 2.4
const TIME_BETWEEN_WAVES := 1.5
const TIME_BETWEEN_ZOMBIES := 0.35

var screen := "menu"
var health := STARTING_HEALTH
var zombies_passed := 0
var zombies_killed := 0
var zombies: Array[Dictionary] = []
var wave := 0
var zombies_left_to_spawn := 0
var wave_delay := 0.5
var spawn_delay := 0.0

var survivor_spawn := -1
var survivor_health := SURVIVOR_MAX_HEALTH
var survivor_alive := true
var survivor_selected := false
var dragging_survivor := false
var drag_position := Vector2.ZERO
var pointer_down_position := Vector2.ZERO
var fire_cooldown := 0.0
var survivor_position := Vector2.ZERO
var survivor_target := Vector2.ZERO
var survivor_is_walking := false
var survivor_aim_angle := PI
var shots: Array[Dictionary] = []
var map_offset := Vector2.ZERO
var map_dragging := false
var map_drag_position := Vector2.ZERO

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

	_update_wave(delta)
	_update_zombies(delta)
	if screen != "playing":
		return
	_update_survivor(delta)

	for shot in shots.duplicate():
		shot.life -= delta
		if shot.life <= 0.0:
			shots.erase(shot)

	var survivor_status := "%d" % survivor_health if survivor_spawn >= 0 and survivor_alive else ("DEAD" if survivor_spawn >= 0 else "—")
	health_label.text = "TOWN: %d    SURVIVOR: %s    WAVE: %d" % [health, survivor_status, wave]
	queue_redraw()

func _update_wave(delta: float) -> void:
	if zombies_left_to_spawn > 0:
		spawn_delay -= delta
		if spawn_delay <= 0.0:
			_spawn_zombie()
			zombies_left_to_spawn -= 1
			spawn_delay = TIME_BETWEEN_ZOMBIES
	elif zombies.is_empty():
		wave_delay -= delta
		if wave_delay <= 0.0:
			wave += 1
			zombies_left_to_spawn = 1 if wave <= 2 else wave - 1
			spawn_delay = 0.0
			wave_delay = TIME_BETWEEN_WAVES

func _spawn_zombie() -> void:
	var road := _road_rect()
	zombies.append({
		"x": -0.1,
		"y": road.position.y + road.size.y * 0.5,
		"hp": ZOMBIE_MAX_HEALTH,
		"alerted": false,
		"attack_cooldown": 0.0,
		"aim_angle": 0.0
	})

func _update_zombies(delta: float) -> void:
	for zombie in zombies.duplicate():
		if zombie.alerted and survivor_alive and survivor_spawn >= 0:
			var zombie_position := _zombie_position(zombie)
			var distance := zombie_position.distance_to(survivor_position)
			var desired_angle := zombie_position.angle_to_point(survivor_position)
			zombie.aim_angle = rotate_toward(zombie.aim_angle, desired_angle, SURVIVOR_TURN_SPEED * delta)
			if distance > ZOMBIE_ATTACK_RANGE:
				var direction := zombie_position.direction_to(survivor_position)
				zombie.x += direction.x * ZOMBIE_CHASE_SPEED * delta / size.x
				zombie.y += direction.y * ZOMBIE_CHASE_SPEED * delta
			else:
				zombie.attack_cooldown -= delta
				if zombie.attack_cooldown <= 0.0:
					survivor_health -= 1
					zombie.attack_cooldown = ZOMBIE_ATTACK_RATE
					if survivor_health <= 0:
						_kill_survivor()
		else:
			zombie.aim_angle = rotate_toward(zombie.aim_angle, 0.0, SURVIVOR_TURN_SPEED * delta)
			zombie.x += ZOMBIE_SPEED * delta

		if zombie.x > 1.08:
			zombies.erase(zombie)
			zombies_passed += 1
			health -= 1
			if health <= 0:
				_show_results()
				return

func _kill_survivor() -> void:
	survivor_health = 0
	survivor_alive = false
	survivor_selected = false
	dragging_survivor = false
	survivor_is_walking = false
	for zombie in zombies:
		zombie.alerted = false

func _update_survivor(delta: float) -> void:
	if survivor_spawn < 0 or not survivor_alive:
		return

	survivor_target = _spawn_points()[survivor_spawn]
	var target := _closest_zombie()
	var distance_to_zombie := INF
	if not target.is_empty():
		distance_to_zombie = survivor_position.distance_to(_zombie_position(target))

	var zombie_in_range := distance_to_zombie <= _survivor_range()
	var zombie_in_awareness := distance_to_zombie <= _survivor_range() * SURVIVOR_AWARENESS_MULTIPLIER
	if zombie_in_awareness:
		var desired_angle := survivor_position.angle_to_point(_zombie_position(target))
		survivor_aim_angle = rotate_toward(survivor_aim_angle, desired_angle, SURVIVOR_TURN_SPEED * delta)
	elif survivor_position.distance_to(survivor_target) > 1.0:
		var walk_angle := survivor_position.angle_to_point(survivor_target)
		survivor_aim_angle = rotate_toward(survivor_aim_angle, walk_angle, SURVIVOR_TURN_SPEED * delta)

	if zombie_in_range:
		survivor_is_walking = false
		fire_cooldown -= delta
		if fire_cooldown <= 0.0:
			_shoot(target)
	elif survivor_position.distance_to(survivor_target) > 1.0:
		survivor_is_walking = true
		survivor_position = survivor_position.move_toward(survivor_target, SURVIVOR_SPEED * delta)
	else:
		survivor_is_walking = false

func _closest_zombie() -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance := INF
	for zombie in zombies:
		var distance := survivor_position.distance_to(_zombie_position(zombie))
		if distance < closest_distance:
			closest = zombie
			closest_distance = distance
	return closest

func _shoot(target: Dictionary) -> void:
	if target.is_empty() or not zombies.has(target):
		return
	var target_position := _zombie_position(target)
	shots.append({"start":survivor_position, "end":target_position, "life":0.12})
	for zombie in zombies:
		zombie.alerted = true
	fire_cooldown = FIRE_RATE
	target.hp -= 1
	if target.hp <= 0:
		zombies.erase(target)
		zombies_killed += 1

func _start_game() -> void:
	screen = "playing"
	health = STARTING_HEALTH
	zombies_passed = 0
	zombies_killed = 0
	zombies.clear()
	wave = 0
	zombies_left_to_spawn = 0
	wave_delay = 0.5
	spawn_delay = 0.0
	survivor_spawn = -1
	survivor_health = SURVIVOR_MAX_HEALTH
	survivor_alive = true
	survivor_selected = false
	dragging_survivor = false
	fire_cooldown = 0.0
	survivor_aim_angle = PI
	shots.clear()
	map_offset = Vector2.ZERO
	map_dragging = false
	title_label.hide()
	results_label.hide()
	begin_button.hide()
	retry_button.hide()
	menu_button.hide()
	health_label.show()
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
	health_label.hide()
	title_label.show()
	title_label.text = "THE TOWN FELL"
	results_label.text = "Reached wave %d\n%d zombies killed" % [wave, zombies_killed]
	results_label.show()
	begin_button.hide()
	retry_button.show()
	menu_button.show()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if screen != "playing":
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			map_dragging = not _handle_pointer_down(event.position)
			map_drag_position = event.position
		else:
			if dragging_survivor:
				_handle_pointer_up(event.position)
			map_dragging = false
	elif event is InputEventScreenDrag:
		if dragging_survivor:
			drag_position = event.position
		elif map_dragging:
			map_offset += event.position - map_drag_position
			map_drag_position = event.position
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			map_dragging = not _handle_pointer_down(event.position)
			map_drag_position = event.position
		else:
			if dragging_survivor:
				_handle_pointer_up(event.position)
			map_dragging = false
	elif event is InputEventMouseMotion:
		if dragging_survivor:
			drag_position = event.position
		elif map_dragging:
			map_offset += event.position - map_drag_position
			map_drag_position = event.position
		queue_redraw()

func _handle_pointer_down(position: Vector2) -> bool:
	var touched_available_survivor := survivor_spawn < 0 and _survivor_card_rect().has_point(position)
	var touched_placed_survivor := survivor_spawn >= 0 and survivor_alive and (survivor_position + map_offset).distance_to(position) <= 42.0
	if touched_available_survivor or touched_placed_survivor:
		survivor_selected = true
		dragging_survivor = true
		drag_position = position
		pointer_down_position = position
		queue_redraw()
		return true
	elif survivor_selected:
		var index := _spawn_point_at(position)
		if index >= 0:
			_set_survivor_destination(index)
			return true
	return false

func _handle_pointer_up(position: Vector2) -> void:
	if not dragging_survivor:
		return
	dragging_survivor = false

	# A short press selects him; a drag orders him immediately.
	if pointer_down_position.distance_to(position) > 10.0:
		var index := _spawn_point_at(position)
		if index >= 0:
			_set_survivor_destination(index)
	queue_redraw()

func _set_survivor_destination(index: int) -> void:
	if survivor_spawn < 0:
		_place_survivor(index)
		return
	survivor_spawn = index
	survivor_target = _spawn_points()[index]
	survivor_is_walking = survivor_position.distance_to(survivor_target) > 1.0
	survivor_selected = false
	dragging_survivor = false
	queue_redraw()

func _place_survivor(index: int) -> void:
	survivor_spawn = index
	survivor_target = _spawn_points()[index]
	survivor_position = Vector2(size.x + 55.0, survivor_target.y)
	survivor_aim_angle = PI
	survivor_is_walking = true
	survivor_selected = false
	dragging_survivor = false
	fire_cooldown = 0.0
	queue_redraw()

func _spawn_point_at(position: Vector2) -> int:
	position -= map_offset
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

func _zombie_position(zombie: Dictionary) -> Vector2:
	return Vector2(zombie.x * size.x, zombie.y)

func _survivor_range() -> float:
	return size.x / MAP_WIDTH_METERS * SURVIVOR_RANGE_METERS

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#111812"))
	if screen != "playing":
		return

	var field := _field_rect()
	var road := _road_rect()
	draw_rect(Rect2(field.position + map_offset, field.size), Color("#334a35"))
	draw_rect(Rect2(road.position + map_offset, road.size), Color("#5b5a50"))
	draw_line(Vector2(map_offset.x, road.position.y + map_offset.y), Vector2(size.x + map_offset.x, road.position.y + map_offset.y), Color("#7b795f"), 4)
	draw_line(Vector2(map_offset.x, road.end.y + map_offset.y), Vector2(size.x + map_offset.x, road.end.y + map_offset.y), Color("#7b795f"), 4)

	var points := _spawn_points()
	for i in points.size():
		var point := points[i] + map_offset
		var occupied := i == survivor_spawn
		var point_color := Color("#d9ba58") if survivor_selected and not occupied else Color("#78917a")
		draw_circle(point, 30, Color(point_color, 0.35))
		draw_arc(point, 30, 0, TAU, 32, point_color, 3)
		if not occupied:
			draw_string(ThemeDB.fallback_font, point + Vector2(-7, 7), "+", HORIZONTAL_ALIGNMENT_CENTER, 14, 22, point_color)

	if survivor_spawn >= 0:
		var survivor_screen := survivor_position + map_offset
		if survivor_alive:
			draw_circle(survivor_screen, _survivor_range(), Color(0.45, 0.72, 0.48, 0.08))
			draw_arc(survivor_screen, _survivor_range(), 0, TAU, 48, Color(0.45, 0.72, 0.48, 0.25), 2)
		draw_set_transform(survivor_screen, survivor_aim_angle)
		var survivor_color := Color.WHITE if survivor_alive else Color(0.35, 0.35, 0.35, 1.0)
		draw_texture_rect(SURVIVOR_TEXTURE, Rect2(Vector2(-38, -32), Vector2(76, 64)), false, survivor_color)
		draw_set_transform(Vector2.ZERO, 0.0)
		var survivor_bar := survivor_screen + Vector2(-28, -42)
		draw_rect(Rect2(survivor_bar, Vector2(56, 6)), Color("#251f1f"))
		draw_rect(Rect2(survivor_bar, Vector2(56.0 * survivor_health / SURVIVOR_MAX_HEALTH, 6)), Color("#63d471"))

	for zombie in zombies:
		var zombie_position := _zombie_position(zombie) + map_offset
		draw_set_transform(zombie_position, zombie.aim_angle)
		draw_texture_rect(ZOMBIE_TEXTURE, Rect2(Vector2(-30, -39), Vector2(60, 78)), false)
		draw_set_transform(Vector2.ZERO, 0.0)
		var bar_position := zombie_position + Vector2(-25, -47)
		draw_rect(Rect2(bar_position, Vector2(50, 6)), Color("#251f1f"))
		draw_rect(Rect2(bar_position, Vector2(50.0 * zombie.hp / ZOMBIE_MAX_HEALTH, 6)), Color("#d85a55"))

	for shot in shots:
		draw_line(shot.start + map_offset, shot.end + map_offset, Color("#ffe184"), 3)
		draw_circle(shot.end + map_offset, 4, Color("#fff4b0"))

	if survivor_spawn < 0:
		var card := _survivor_card_rect()
		var card_color := Color("#6f8e70") if survivor_selected else Color("#344d38")
		draw_rect(card, card_color)
		draw_rect(card, Color("#9fba9e"), false, 2)
		draw_texture_rect(SURVIVOR_TEXTURE, Rect2(card.position + Vector2(23, 5), Vector2(58, 49)), false)
		draw_string(ThemeDB.fallback_font, card.position + Vector2(10, 78), "SURVIVOR • 3m", HORIZONTAL_ALIGNMENT_CENTER, 84, 13, Color.WHITE)

	if dragging_survivor:
		draw_texture_rect(SURVIVOR_TEXTURE, Rect2(drag_position - Vector2(38, 32), Vector2(76, 64)), false, Color(1, 1, 1, 0.75))
