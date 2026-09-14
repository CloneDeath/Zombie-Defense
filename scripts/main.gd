extends Control

const ZOMBIE_TEXTURE := preload("res://assets/kenney/zombie.png")
const SURVIVOR_TEXTURE := preload("res://assets/kenney/survivor.png")

const WORLD_SIZE := Vector2(1800, 1000)
const PATH_POINTS := [
	Vector2(0, 510), Vector2(330, 510), Vector2(330, 230),
	Vector2(720, 230), Vector2(720, 760), Vector2(1120, 760),
	Vector2(1120, 390), Vector2(1480, 390), Vector2(1480, 610),
	Vector2(1800, 610)
]
const SPAWN_POINTS := [
	Vector2(540, 130), Vector2(900, 650),
	Vector2(1250, 290), Vector2(1580, 720)
]

const STARTING_HEALTH := 10
const ZOMBIE_SPEED := 62.0
const ZOMBIE_CHASE_SPEED := 55.0
const ZOMBIE_MAX_HEALTH := 3
const ZOMBIE_ATTACK_RANGE := 34.0
const ZOMBIE_ATTACK_RATE := 0.8
const SURVIVOR_MAX_HEALTH := 10
const SURVIVOR_SPEED := 120.0
const SURVIVOR_RANGE := 300.0
const SURVIVOR_AWARENESS := 600.0
const FIRE_RATE := 0.65
const TURN_SPEED := 2.4
const TIME_BETWEEN_WAVES := 1.5
const TIME_BETWEEN_ZOMBIES := 0.35
const MIN_ZOOM := 0.42
const MAX_ZOOM := 1.5

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
var survivor_position := Vector2.ZERO
var survivor_target := Vector2.ZERO
var survivor_aim_angle := PI
var survivor_selected := false
var dragging_survivor := false
var drag_position := Vector2.ZERO
var pointer_down_position := Vector2.ZERO
var fire_cooldown := 0.0
var shots: Array[Dictionary] = []

var camera_zoom := 0.7
var camera_offset := Vector2.ZERO
var camera_dragging := false
var active_touches := {}
var pinch_distance := 0.0

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
		_clamp_camera()
		queue_redraw()

func _layout_ui() -> void:
	var center_x := size.x * 0.5
	var portrait := size.y > size.x
	title_label.position = Vector2(10, size.y * (0.22 if portrait else 0.18))
	title_label.size = Vector2(size.x - 20, 55)
	title_label.add_theme_font_size_override("font_size", 32 if portrait else 38)
	version_label.position = Vector2(size.x - 225, 8)
	version_label.size = Vector2(210, 22)
	health_label.position = Vector2(10, 38)
	health_label.size = Vector2(size.x - 20, 40)
	health_label.add_theme_font_size_override("font_size", 17 if portrait else 22)
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
	zombies.append({
		"progress": 0.0,
		"position": PATH_POINTS[0],
		"hp": ZOMBIE_MAX_HEALTH,
		"alerted": false,
		"attack_cooldown": 0.0,
		"aim_angle": 0.0
	})

func _update_zombies(delta: float) -> void:
	for zombie in zombies.duplicate():
		if zombie.alerted and survivor_alive and survivor_spawn >= 0:
			var distance := zombie.position.distance_to(survivor_position)
			var desired_angle := zombie.position.angle_to_point(survivor_position)
			zombie.aim_angle = rotate_toward(zombie.aim_angle, desired_angle, TURN_SPEED * delta)
			if distance > ZOMBIE_ATTACK_RANGE:
				zombie.position = zombie.position.move_toward(survivor_position, ZOMBIE_CHASE_SPEED * delta)
			else:
				zombie.attack_cooldown -= delta
				if zombie.attack_cooldown <= 0.0:
					survivor_health -= 1
					zombie.attack_cooldown = ZOMBIE_ATTACK_RATE
					if survivor_health <= 0:
						_kill_survivor()
		else:
			zombie.progress += ZOMBIE_SPEED * delta
			var path_sample := _sample_path(zombie.progress)
			zombie.position = path_sample.position
			zombie.aim_angle = rotate_toward(zombie.aim_angle, path_sample.angle, TURN_SPEED * delta)
			if path_sample.finished:
				zombies.erase(zombie)
				zombies_passed += 1
				health -= 1
				if health <= 0:
					_show_results()
					return

func _sample_path(distance: float) -> Dictionary:
	var remaining := distance
	for i in PATH_POINTS.size() - 1:
		var start: Vector2 = PATH_POINTS[i]
		var finish: Vector2 = PATH_POINTS[i + 1]
		var segment_length := start.distance_to(finish)
		if remaining <= segment_length:
			var position := start.lerp(finish, remaining / segment_length)
			return {"position":position, "angle":start.angle_to_point(finish), "finished":false}
		remaining -= segment_length
	var last_angle: float = PATH_POINTS[-2].angle_to_point(PATH_POINTS[-1])
	return {"position":PATH_POINTS[-1], "angle":last_angle, "finished":true}

func _kill_survivor() -> void:
	survivor_health = 0
	survivor_alive = false
	survivor_selected = false
	dragging_survivor = false
	for zombie in zombies:
		zombie.alerted = false

func _update_survivor(delta: float) -> void:
	if survivor_spawn < 0 or not survivor_alive:
		return
	survivor_target = SPAWN_POINTS[survivor_spawn]
	var target := _closest_zombie()
	var distance_to_zombie := INF
	if not target.is_empty():
		distance_to_zombie = survivor_position.distance_to(target.position)

	if distance_to_zombie <= SURVIVOR_AWARENESS:
		var desired_angle := survivor_position.angle_to_point(target.position)
		survivor_aim_angle = rotate_toward(survivor_aim_angle, desired_angle, TURN_SPEED * delta)
	elif survivor_position.distance_to(survivor_target) > 1.0:
		var walk_angle := survivor_position.angle_to_point(survivor_target)
		survivor_aim_angle = rotate_toward(survivor_aim_angle, walk_angle, TURN_SPEED * delta)

	if distance_to_zombie <= SURVIVOR_RANGE:
		fire_cooldown -= delta
		if fire_cooldown <= 0.0:
			_shoot(target)
	elif survivor_position.distance_to(survivor_target) > 1.0:
		survivor_position = survivor_position.move_toward(survivor_target, SURVIVOR_SPEED * delta)

func _closest_zombie() -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance := INF
	for zombie in zombies:
		var distance := survivor_position.distance_to(zombie.position)
		if distance < closest_distance:
			closest = zombie
			closest_distance = distance
	return closest

func _shoot(target: Dictionary) -> void:
	if target.is_empty() or not zombies.has(target):
		return
	shots.append({"start":survivor_position, "end":target.position, "life":0.12})
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
	survivor_spawn = -1
	survivor_health = SURVIVOR_MAX_HEALTH
	survivor_alive = true
	survivor_selected = false
	dragging_survivor = false
	fire_cooldown = 0.0
	survivor_aim_angle = PI
	shots.clear()
	_reset_camera()
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
			active_touches[event.index] = event.position
			if active_touches.size() == 1:
				camera_dragging = not _handle_pointer_down(event.position)
			elif active_touches.size() == 2:
				dragging_survivor = false
				camera_dragging = false
				pinch_distance = _touch_distance()
		else:
			camera_dragging = false
		else:
			if active_touches.size() == 1 and dragging_survivor:
				_handle_pointer_up(event.position)
			active_touches.erase(event.index)
			if active_touches.is_empty():
				camera_dragging = false
	elif event is InputEventScreenDrag:
		active_touches[event.index] = event.position
		if active_touches.size() >= 2:
			var new_distance := _touch_distance()
			if pinch_distance > 0.0:
				_zoom_at(_touch_center(), camera_zoom * new_distance / pinch_distance)
			pinch_distance = new_distance
		elif dragging_survivor:
			drag_position = event.position
		elif camera_dragging:
			camera_offset += event.relative
			_clamp_camera()
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.position, camera_zoom * 1.12)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.position, camera_zoom / 1.12)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				camera_dragging = not _handle_pointer_down(event.position)
			else:
				if dragging_survivor:
					_handle_pointer_up(event.position)
				camera_dragging = false
	elif event is InputEventMouseMotion:
		if dragging_survivor:
			drag_position = event.position
		elif camera_dragging:
			camera_offset += event.relative
			_clamp_camera()
		queue_redraw()

func _handle_pointer_down(position: Vector2) -> bool:
	var survivor_screen := _world_to_screen(survivor_position)
	var touched_card := survivor_spawn < 0 and _survivor_card_rect().has_point(position)
	var touched_survivor := survivor_spawn >= 0 and survivor_alive and survivor_screen.distance_to(position) <= 42.0
	if touched_card or touched_survivor:
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
	dragging_survivor = false
	if pointer_down_position.distance_to(position) > 10.0:
		var index := _spawn_point_at(position)
		if index >= 0:
			_set_survivor_destination(index)
	queue_redraw()

func _set_survivor_destination(index: int) -> void:
	if survivor_spawn < 0:
		survivor_spawn = index
		survivor_position = Vector2(WORLD_SIZE.x + 65.0, SPAWN_POINTS[index].y)
		survivor_aim_angle = PI
	survivor_spawn = index
	survivor_target = SPAWN_POINTS[index]
	survivor_selected = false
	dragging_survivor = false
	fire_cooldown = 0.0
	queue_redraw()

func _spawn_point_at(screen_position: Vector2) -> int:
	var world_position := _screen_to_world(screen_position)
	for i in SPAWN_POINTS.size():
		if SPAWN_POINTS[i].distance_to(world_position) <= 44.0:
			return i
	return -1

func _reset_camera() -> void:
	camera_zoom = clampf(minf(size.x / 900.0, (size.y - 120.0) / 650.0), MIN_ZOOM, 1.0)
	camera_offset = Vector2(20, 85) - Vector2(180, 300) * camera_zoom
	_clamp_camera()

func _zoom_at(screen_position: Vector2, new_zoom: float) -> void:
	var world_before := _screen_to_world(screen_position)
	camera_zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	camera_offset = screen_position - world_before * camera_zoom
	_clamp_camera()
	queue_redraw()

func _clamp_camera() -> void:
	var top := 78.0
	var bottom := size.y - 112.0
	var scaled := WORLD_SIZE * camera_zoom
	if scaled.x <= size.x:
		camera_offset.x = (size.x - scaled.x) * 0.5
	else:
		camera_offset.x = clampf(camera_offset.x, size.x - scaled.x, 0.0)
	if scaled.y <= bottom - top:
		camera_offset.y = top + (bottom - top - scaled.y) * 0.5
	else:
		camera_offset.y = clampf(camera_offset.y, bottom - scaled.y, top)

func _touch_distance() -> float:
	var values := active_touches.values()
	return values[0].distance_to(values[1])

func _touch_center() -> Vector2:
	var values := active_touches.values()
	return (values[0] + values[1]) * 0.5

func _world_to_screen(world_position: Vector2) -> Vector2:
	return world_position * camera_zoom + camera_offset

func _screen_to_world(screen_position: Vector2) -> Vector2:
	return (screen_position - camera_offset) / camera_zoom

func _survivor_card_rect() -> Rect2:
	return Rect2(size.x * 0.5 - 52, size.y - 105, 104, 92)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#111812"))
	if screen != "playing":
		return

	draw_set_transform(camera_offset, 0.0, Vector2(camera_zoom, camera_zoom))
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#334a35"))
	draw_polyline(PackedVector2Array(PATH_POINTS), Color("#777565"), 116.0, true)
	draw_polyline(PackedVector2Array(PATH_POINTS), Color("#a09d87"), 6.0, true)

	for i in SPAWN_POINTS.size():
		var occupied := i == survivor_spawn
		var point_color := Color("#d9ba58") if survivor_selected and not occupied else Color("#78917a")
		draw_circle(SPAWN_POINTS[i], 34, Color(point_color, 0.35))
		draw_arc(SPAWN_POINTS[i], 34, 0, TAU, 32, point_color, 3.0 / camera_zoom)
		if not occupied:
			draw_string(ThemeDB.fallback_font, SPAWN_POINTS[i] + Vector2(-8, 8), "+", HORIZONTAL_ALIGNMENT_CENTER, 16, 24, point_color)

	if survivor_spawn >= 0:
		if survivor_alive:
			draw_circle(survivor_position, SURVIVOR_RANGE, Color(0.45, 0.72, 0.48, 0.07))
			draw_arc(survivor_position, SURVIVOR_RANGE, 0, TAU, 48, Color(0.45, 0.72, 0.48, 0.25), 2.0 / camera_zoom)
		draw_set_transform(camera_offset + survivor_position * camera_zoom, survivor_aim_angle, Vector2(camera_zoom, camera_zoom))
		var survivor_color := Color.WHITE if survivor_alive else Color(0.35, 0.35, 0.35, 1)
		draw_texture_rect(SURVIVOR_TEXTURE, Rect2(Vector2(-38, -32), Vector2(76, 64)), false, survivor_color)
		draw_set_transform(camera_offset, 0.0, Vector2(camera_zoom, camera_zoom))
		var survivor_bar := survivor_position + Vector2(-28, -42)
		draw_rect(Rect2(survivor_bar, Vector2(56, 6)), Color("#251f1f"))
		draw_rect(Rect2(survivor_bar, Vector2(56.0 * survivor_health / SURVIVOR_MAX_HEALTH, 6)), Color("#63d471"))

	for zombie in zombies:
		draw_set_transform(camera_offset + zombie.position * camera_zoom, zombie.aim_angle, Vector2(camera_zoom, camera_zoom))
		draw_texture_rect(ZOMBIE_TEXTURE, Rect2(Vector2(-30, -39), Vector2(60, 78)), false)
		draw_set_transform(camera_offset, 0.0, Vector2(camera_zoom, camera_zoom))
		var bar_position: Vector2 = zombie.position + Vector2(-25, -47)
		draw_rect(Rect2(bar_position, Vector2(50, 6)), Color("#251f1f"))
		draw_rect(Rect2(bar_position, Vector2(50.0 * zombie.hp / ZOMBIE_MAX_HEALTH, 6)), Color("#d85a55"))

	for shot in shots:
		draw_line(shot.start, shot.end, Color("#ffe184"), 3.0 / camera_zoom)
		draw_circle(shot.end, 4.0 / camera_zoom, Color("#fff4b0"))

	draw_set_transform(Vector2.ZERO, 0.0)
	draw_rect(Rect2(0, 0, size.x, 78), Color("#111812"))
	draw_rect(Rect2(0, size.y - 112, size.x, 112), Color("#111812"))

	if survivor_spawn < 0:
		var card := _survivor_card_rect()
		var card_color := Color("#6f8e70") if survivor_selected else Color("#344d38")
		draw_rect(card, card_color)
		draw_rect(card, Color("#9fba9e"), false, 2)
		draw_texture_rect(SURVIVOR_TEXTURE, Rect2(card.position + Vector2(23, 5), Vector2(58, 49)), false)
		draw_string(ThemeDB.fallback_font, card.position + Vector2(10, 78), "SURVIVOR • 3m", HORIZONTAL_ALIGNMENT_CENTER, 84, 13, Color.WHITE)

	if dragging_survivor:
		draw_texture_rect(SURVIVOR_TEXTURE, Rect2(drag_position - Vector2(38, 32), Vector2(76, 64)), false, Color(1, 1, 1, 0.75))
