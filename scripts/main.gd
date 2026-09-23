extends Control

const ZOMBIE_TEXTURE := preload("res://assets/kenney/zombie.png")
const SURVIVOR_TEXTURE := preload("res://assets/kenney/survivor.png")
const BASEBALL_TEXTURE := preload("res://assets/kenney/baseball.png")
const GRASS_TEXTURE := preload("res://assets/kenney/grass.png")
const ROAD_TEXTURE := preload("res://assets/kenney/road.png")
const SIDEWALK_TEXTURE := preload("res://assets/kenney/sidewalk.png")
const TREE_TEXTURE := preload("res://assets/kenney/tree.png")
const CAR_TEXTURE := preload("res://assets/kenney/car.png")
const MANHOLE_TEXTURE := preload("res://assets/kenney/manhole.png")
const DEBRIS_TEXTURE := preload("res://assets/kenney/debris.png")
const OIL_SPILL_TEXTURE := preload("res://assets/kenney/oil_spill.png")
const HOUSE_TILE_FLOOR_TEXTURE := preload("res://assets/kenney/house_tile_floor.png")
const HOUSE_WOOD_FLOOR_TEXTURE := preload("res://assets/kenney/house_wood_floor.png")
const HOUSE_CRATE_TEXTURE := preload("res://assets/kenney/house_crate.png")
const HOUSE_PLANT_TEXTURE := preload("res://assets/kenney/house_plant.png")
const HOUSE_SOFA_TEXTURE := preload("res://assets/kenney/house_sofa.png")
const HOUSE_TABLE_TEXTURE := preload("res://assets/kenney/house_table.png")
const HOUSE_FRIDGE_TEXTURE := preload("res://assets/kenney/house_fridge.png")
const HOUSE_STOVE_TEXTURE := preload("res://assets/kenney/house_stove.png")
const STARTING_HEALTH := 10
const TILE_SIZE := 64.0
const MAP_SIZE_TILES := 20
const MAP_OVERSCAN := TILE_SIZE * 24.0
const CAMERA_NODE_EDGE_RATIO := 0.18
const CAMERA_SPRING_SPEED := 11.0
const OVERSCROLL_RESISTANCE := 0.32
const ZOMBIE_SPEED := 0.069
const ZOMBIE_CHASE_SPEED := 55.0
const ZOMBIE_ATTACK_RANGE := 46.0
const ZOMBIE_ATTACK_RATE := 0.8
const ZOMBIE_COLLISION_DIAMETER := 44.0
const SURVIVOR_COLLISION_RADIUS := 22.0
const ZOMBIE_COLLISION_RADIUS := 22.0
const ZOMBIE_HIT_KNOCKBACK := 12.0
const ZOMBIE_ACCELERATION := 1.8
const ZOMBIE_TURN_SPEED := 0.85
const GUNSHOT_HEARING_RANGE_METERS := 8.0
const GUNSHOT_RETARGET_CHANCE := 0.35
const SURVIVOR_MAX_HEALTH := 10
const BASEBALL_MAX_HEALTH := 12
const BASEBALL_ROAM_METERS := 7.0
const BASEBALL_MELEE_METERS := 0.75
const BASEBALL_WAIT_DISTANCE_METERS := 2.0
const BASEBALL_SPEED := 95.0
const BASEBALL_RECHARGE_SPEED := 42.0
const BASEBALL_ATTACK_RATE := 1.5
const BASEBALL_DAMAGE := 0.5
const BASEBALL_DAMAGE_PER_LEVEL := 0.15
const BASEBALL_KNOCKBACK_SPEED := 420.0
const ZOMBIE_KNOCKBACK_DECELERATION := 1225.0
const BASEBALL_AOE_METERS := 0.9
const BASEBALL_SWING_DURATION := 0.28
const ZOMBIE_MAX_HEALTH := 3
const FIRE_RATE := 0.65
const COP_ACCURACY := 0.78
const COP_MAX_SPREAD_DEGREES := 14.0
const ZOMBIE_HIT_RADIUS := 23.0
const MAGAZINE_SIZE := 10
const RELOAD_TIME := 1.8
const EARLY_RELOAD_AT := 5
const BLOOD_PARTICLE_LIFE := 0.45
const LEVEL_UP_EFFECT_LIFE := 1.25
const SURVIVOR_SPEED := 120.0
const SURVIVOR_COMBAT_SPEED := 40.0
const OFF_MAP_SURVIVOR_SPEED_MULTIPLIER := 4.0
const STREET_WIDTH_TILES := 6
const SIDEWALK_WIDTH_TILES := 1
const SURVIVOR_RANGE_METERS := 5.0
const SURVIVOR_AWARENESS_MULTIPLIER := 2.0
const SURVIVOR_TURN_SPEED := 2.4
const TIME_BETWEEN_WAVES := 8.0
const MIN_TIME_BETWEEN_ZOMBIES := 0.08
const MAX_TIME_BETWEEN_ZOMBIES := 0.48

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
var survivor_max_health := SURVIVOR_MAX_HEALTH
var cop_level := 1
var cop_xp := 0
var cop_xp_to_next := 3
var cop_kills := 0
var baseball_spawn := -1
var baseball_max_health := BASEBALL_MAX_HEALTH
var baseball_level := 1
var baseball_xp := 0
var baseball_xp_to_next := 3
var baseball_health := BASEBALL_MAX_HEALTH
var baseball_alive := true
var baseball_selected := false
var baseball_position := Vector2.ZERO
var baseball_target := Vector2.ZERO
var baseball_is_walking := false
var baseball_zone_move := false
var baseball_patrol_target := Vector2.ZERO
var baseball_patrol_timer := 0.0
var baseball_retreating := false
var baseball_evacuated := false
var baseball_aim_angle := PI
var baseball_attack_cooldown := 0.0
var baseball_swing_time := 0.0
var baseball_kills := 0
var dragging_unit := ""
var survivor_health := SURVIVOR_MAX_HEALTH
var survivor_alive := true
var survivor_selected := false
var dragging_survivor := false
var drag_position := Vector2.ZERO
var pointer_down_position := Vector2.ZERO
var fire_cooldown := 0.0
var ammo := MAGAZINE_SIZE
var reload_time_remaining := 0.0
var is_reloading := false
var survivor_position := Vector2.ZERO
var survivor_target := Vector2.ZERO
var survivor_is_walking := false
var survivor_retreating := false
var survivor_evacuated := false
var survivor_aim_angle := PI
var shots: Array[Dictionary] = []
var blood_particles: Array[Dictionary] = []
var level_up_effects: Array[Dictionary] = []
var map_offset := Vector2.ZERO
var map_dragging := false
var map_drag_position := Vector2.ZERO
var map_zoom := 1.0
var active_touches := {}
var pinch_distance := 0.0
var game_paused := false
var fast_forward := false

var title_label: Label
var health_label: Label
var results_label: Label
var version_label: Label
var begin_button: Button
var map_button: Button
var start_map_button: Button
var selection_back_button: Button
var retry_button: Button
var menu_button: Button
var pause_button: Button
var fast_forward_button: Button
var retreat_button: Button

func _ready() -> void:
	title_label = _make_label(38, Color.WHITE)
	title_label.text = "ZOMBIE DEFENSE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label = _make_label(24, Color("#f5e8c8"))
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results_label = _make_label(24, Color.WHITE)
	results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label = _make_label(16, Color("#c4d0c1"))
	version_label.text = "%s • %s" % [BuildVersion.BRANCH, BuildVersion.COMMIT]
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	begin_button = _make_button("BEGIN")
	begin_button.pressed.connect(_show_overworld)
	map_button = _make_button("RURAL CROSSROADS")
	map_button.pressed.connect(_show_map_preview)
	start_map_button = _make_button("START")
	start_map_button.pressed.connect(_start_game)
	selection_back_button = _make_button("BACK")
	selection_back_button.pressed.connect(_selection_back)
	retry_button = _make_button("RETRY")
	retry_button.pressed.connect(_start_game)
	menu_button = _make_button("BACK TO MENU")
	menu_button.pressed.connect(_show_menu)
	pause_button = _make_button("PAUSE")
	pause_button.pressed.connect(_toggle_pause)
	fast_forward_button = _make_button("FF")
	fast_forward_button.pressed.connect(_toggle_fast_forward)
	retreat_button = _make_button("RETREAT")
	retreat_button.pressed.connect(_retreat_survivors)
	_show_menu()
	_layout_ui()
	if DisplayServer.get_name() == "headless":
		call_deferred("_run_headless_gameplay_smoke_test")

func _run_headless_gameplay_smoke_test() -> void:
	_show_overworld()
	_show_map_preview()
	_start_game()
	_place_survivor(0)
	_place_baseball_survivor(1)

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
	version_label.position = Vector2(size.x - 285, 6)
	version_label.size = Vector2(270, 28)
	health_label.position = Vector2(10, 45)
	health_label.size = Vector2(size.x - 20, 40)
	health_label.add_theme_font_size_override("font_size", 20 if portrait else 24)
	var selection_screen := screen == "overworld" or screen == "map_preview"
	results_label.position = Vector2(10, size.y * (0.27 if selection_screen else (0.38 if portrait else 0.36)))
	results_label.size = Vector2(size.x - 20, 76)
	begin_button.position = Vector2(center_x - 100, size.y * 0.52)
	begin_button.size = Vector2(200, 58)
	map_button.position = Vector2(center_x - 140, size.y * 0.46)
	map_button.size = Vector2(280, 72)
	start_map_button.position = Vector2(center_x - 95, size.y * 0.75)
	start_map_button.size = Vector2(190, 58)
	selection_back_button.position = Vector2(center_x - 75, size.y * 0.84)
	selection_back_button.size = Vector2(150, 50)
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
	pause_button.position = Vector2(10, 8)
	pause_button.size = Vector2(82, 34)
	pause_button.add_theme_font_size_override("font_size", 14)
	fast_forward_button.position = Vector2(100, 8)
	fast_forward_button.size = Vector2(58, 34)
	fast_forward_button.add_theme_font_size_override("font_size", 14)
	retreat_button.position = Vector2(166, 8)
	retreat_button.size = Vector2(108, 34)
	retreat_button.add_theme_font_size_override("font_size", 14)

func _toggle_pause() -> void:
	game_paused = not game_paused
	pause_button.text = "PLAY" if game_paused else "PAUSE"
	queue_redraw()

func _toggle_fast_forward() -> void:
	fast_forward = not fast_forward
	fast_forward_button.text = "2X" if fast_forward else "FF"

func _retreat_survivors() -> void:
	var has_survivor_to_retreat := false
	if survivor_spawn >= 0 and survivor_alive and not survivor_evacuated:
		survivor_retreating = true
		survivor_selected = false
		has_survivor_to_retreat = true
	if baseball_spawn >= 0 and baseball_alive and not baseball_evacuated:
		baseball_retreating = true
		baseball_zone_move = false
		baseball_selected = false
		has_survivor_to_retreat = true
	retreat_button.disabled = has_survivor_to_retreat
	queue_redraw()

func _show_overworld() -> void:
	screen = "overworld"
	title_label.text = "SELECT MAP"
	title_label.show()
	results_label.text = "Choose where to make your stand."
	results_label.show()
	begin_button.hide()
	map_button.show()
	start_map_button.hide()
	selection_back_button.show()
	menu_button.hide()
	retry_button.hide()
	pause_button.hide()
	fast_forward_button.hide()
	retreat_button.hide()
	health_label.hide()
	_layout_ui()
	queue_redraw()

func _show_map_preview() -> void:
	screen = "map_preview"
	title_label.text = "RURAL CROSSROADS"
	results_label.text = "Rural neighborhood\nZombies enter from the west and escape to the east."
	map_button.hide()
	start_map_button.show()
	selection_back_button.show()
	_layout_ui()
	queue_redraw()

func _selection_back() -> void:
	if screen == "map_preview":
		_show_overworld()
	else:
		_show_menu()

func _process(delta: float) -> void:
	if screen != "playing":
		return
	if game_paused:
		return
	delta *= 2.0 if fast_forward else 1.0

	if not map_dragging and active_touches.size() < 2:
		var resting_offset := _clamped_map_offset(map_offset)
		map_offset = map_offset.lerp(resting_offset, 1.0 - exp(-CAMERA_SPRING_SPEED * delta))

	_update_wave(delta)
	_update_zombies(delta)
	if screen != "playing":
		return
	_update_survivor(delta)
	_update_baseball_survivor(delta)
	_separate_survivors_and_zombies()
	_separate_survivors()

	for shot in shots.duplicate():
		shot.life -= delta
		if shot.life <= 0.0:
			shots.erase(shot)

	for particle in blood_particles.duplicate():
		particle.life -= delta
		particle.position += particle.velocity * delta
		particle.velocity *= 0.90
		if particle.life <= 0.0:
			blood_particles.erase(particle)

	for effect in level_up_effects.duplicate():
		effect.life -= delta
		if effect.life <= 0.0:
			level_up_effects.erase(effect)

	health_label.text = "TOWN: %d    WAVE: %d" % [health, wave]
	queue_redraw()

func _update_wave(delta: float) -> void:
	wave_delay -= delta
	if wave_delay <= 0.0:
		wave += 1
		zombies_left_to_spawn += int(pow(2.0, wave)) - 1
		wave_delay += TIME_BETWEEN_WAVES
		if spawn_delay <= 0.0:
			spawn_delay = randf_range(0.0, 0.2)

	if zombies_left_to_spawn > 0:
		spawn_delay -= delta
		if spawn_delay <= 0.0:
			_spawn_zombie()
			zombies_left_to_spawn -= 1
			spawn_delay = randf_range(
				MIN_TIME_BETWEEN_ZOMBIES,
				MAX_TIME_BETWEEN_ZOMBIES
			)

func _spawn_zombie() -> void:
	var road := _road_rect()
	var edge_margin := TILE_SIZE * 0.4
	var spawn_y := randf_range(road.position.y + edge_margin, road.end.y - edge_margin)
	zombies.append({
		"x": (-MAP_OVERSCAN - TILE_SIZE) / _map_size().x,
		"y": spawn_y,
		"path_offset": spawn_y - _upper_road_y(),
		"route_segment": 0,
		"hp": ZOMBIE_MAX_HEALTH,
		"speed_multiplier": randf_range(0.85, 1.15),
		"movement_factor": 1.0,
		"knockback_velocity": Vector2.ZERO,
		"target_id": "",
		"swarm_angle": randf_range(0.0, TAU),
		"swarm_radius": randf_range(20.0, 30.0),
		"attack_cooldown": 0.0,
		"aim_angle": 0.0
	})

func _update_zombies(delta: float) -> void:
	for zombie in zombies.duplicate():
		zombie.movement_factor = move_toward(
			zombie.movement_factor,
			1.0,
			ZOMBIE_ACCELERATION * delta
		)
		var knockback_velocity: Vector2 = zombie.knockback_velocity
		if not knockback_velocity.is_zero_approx():
			var knocked_position := _zombie_position(zombie) + knockback_velocity * delta
			if _zombie_position_blocked(knocked_position):
				zombie.knockback_velocity = Vector2.ZERO
			else:
				zombie.x = knocked_position.x / _map_size().x
				zombie.y = knocked_position.y
				zombie.knockback_velocity = knockback_velocity.move_toward(
					Vector2.ZERO,
					ZOMBIE_KNOCKBACK_DECELERATION * delta
				)
		# Preserve route progress when a chase carries a zombie through either turn.
		var route_position := _zombie_position(zombie)
		var route_segment := int(zombie.route_segment)
		var half_road := STREET_WIDTH_TILES * TILE_SIZE * 0.5
		if route_segment == 0 and route_position.x >= _main_road_x() - half_road:
			route_segment = 1
		if route_segment <= 1 and route_position.x >= _main_road_x() - half_road and route_position.y >= _lower_road_y() - half_road:
			route_segment = 2
		zombie.route_segment = route_segment
		var target_id := String(zombie.target_id)
		if target_id != "" and not _survivor_target_alive(target_id):
			zombie.target_id = ""
			target_id = ""

		if target_id != "":
			var zombie_position := _zombie_position(zombie)
			var target_position := _survivor_target_position(target_id)
			var swarm_offset := Vector2.RIGHT.rotated(float(zombie.swarm_angle)) * float(zombie.swarm_radius)
			var swarm_position: Vector2 = target_position + swarm_offset
			var distance := zombie_position.distance_to(target_position)
			var desired_angle := zombie_position.angle_to_point(target_position)
			zombie.aim_angle = rotate_toward(zombie.aim_angle, desired_angle, ZOMBIE_TURN_SPEED * delta)
			if distance > ZOMBIE_ATTACK_RANGE:
				var speed: float = ZOMBIE_CHASE_SPEED * zombie.speed_multiplier * zombie.movement_factor
				var moved_position := _move_around_car(zombie_position, swarm_position, speed * delta)
				zombie.x = moved_position.x / _map_size().x
				zombie.y = moved_position.y
			else:
				zombie.attack_cooldown -= delta
				if zombie.attack_cooldown <= 0.0:
					_damage_survivor_target(target_id)
					zombie.attack_cooldown = ZOMBIE_ATTACK_RATE
		else:
			var zombie_position := _zombie_position(zombie)
			var path_offset := float(zombie.path_offset)
			var segment := int(zombie.route_segment)
			var first_turn := Vector2(_main_road_x() - path_offset, _upper_road_y() + path_offset)
			var second_turn := Vector2(_main_road_x() - path_offset, _lower_road_y() - path_offset)
			var route_target := first_turn
			if segment == 1:
				route_target = second_turn
			elif segment >= 2:
				route_target = Vector2(_route_exit_x(), _lower_road_y() - path_offset)
			if zombie_position.distance_to(route_target) <= 8.0 and segment < 2:
				segment += 1
				zombie.route_segment = segment
				if segment == 1:
					route_target = second_turn
				else:
					route_target = Vector2(_route_exit_x(), _lower_road_y() - path_offset)
			var desired_angle := zombie_position.angle_to_point(route_target)
			zombie.aim_angle = rotate_toward(zombie.aim_angle, desired_angle, ZOMBIE_TURN_SPEED * delta)
			var route_speed: float = ZOMBIE_SPEED * _map_size().x * zombie.speed_multiplier * zombie.movement_factor
			var moved_position := _move_around_car(zombie_position, route_target, route_speed * delta)
			zombie.x = moved_position.x / _map_size().x
			zombie.y = moved_position.y

		if int(zombie.route_segment) >= 2 and _zombie_position(zombie).x > _route_exit_x():
			zombies.erase(zombie)
			zombies_passed += 1
			health -= 1
			if health <= 0:
				_show_results()
				return

	_separate_zombies()
	_keep_zombies_out_of_obstacles()

func _zombie_position_blocked(position: Vector2) -> bool:
	var obstacles := _car_obstacle_rects(ZOMBIE_COLLISION_RADIUS)
	obstacles.append(_house_rect().grow(ZOMBIE_COLLISION_RADIUS))
	for obstacle in obstacles:
		if obstacle.has_point(position):
			return true
	return false

func _keep_zombies_out_of_obstacles() -> void:
	var obstacles := _car_obstacle_rects(ZOMBIE_COLLISION_RADIUS)
	obstacles.append(_house_rect().grow(ZOMBIE_COLLISION_RADIUS))
	for zombie in zombies:
		var position := _zombie_position(zombie)
		for obstacle in obstacles:
			if not obstacle.has_point(position):
				continue
			var left_distance := position.x - obstacle.position.x
			var right_distance := obstacle.end.x - position.x
			var top_distance := position.y - obstacle.position.y
			var bottom_distance := obstacle.end.y - position.y
			var nearest := minf(minf(left_distance, right_distance), minf(top_distance, bottom_distance))
			if nearest == left_distance:
				position.x = obstacle.position.x - 1.0
			elif nearest == right_distance:
				position.x = obstacle.end.x + 1.0
			elif nearest == top_distance:
				position.y = obstacle.position.y - 1.0
			else:
				position.y = obstacle.end.y + 1.0
		zombie.x = position.x / _map_size().x
		zombie.y = position.y

func _separate_zombies() -> void:
	var map_width := _map_size().x
	for i in zombies.size():
		for j in range(i + 1, zombies.size()):
			var first: Dictionary = zombies[i]
			var second: Dictionary = zombies[j]
			var first_position := _zombie_position(first)
			var second_position := _zombie_position(second)
			var difference := second_position - first_position
			var distance := difference.length()
			if distance >= ZOMBIE_COLLISION_DIAMETER:
				continue
			var direction := difference / distance if distance > 0.001 else Vector2.UP.rotated(randf() * TAU)
			var correction := direction * (ZOMBIE_COLLISION_DIAMETER - distance) * 0.5
			first_position -= correction
			second_position += correction
			first.x = first_position.x / map_width
			first.y = first_position.y
			second.x = second_position.x / map_width
			second.y = second_position.y

func _separate_survivors_and_zombies() -> void:
	var minimum_distance := SURVIVOR_COLLISION_RADIUS + ZOMBIE_COLLISION_RADIUS
	for zombie in zombies:
		var zombie_position := _zombie_position(zombie)
		var survivor_positions: Array[Vector2] = []
		if survivor_spawn >= 0 and survivor_alive and not survivor_evacuated:
			survivor_positions.append(survivor_position)
		if baseball_spawn >= 0 and baseball_alive and not baseball_evacuated:
			survivor_positions.append(baseball_position)
		for unit_position in survivor_positions:
			var difference := zombie_position - unit_position
			var distance := difference.length()
			if distance >= minimum_distance:
				continue
			var direction := difference / distance if distance > 0.001 else Vector2.RIGHT.rotated(randf() * TAU)
			zombie_position += direction * (minimum_distance - distance)
		zombie.x = zombie_position.x / _map_size().x
		zombie.y = zombie_position.y

func _separate_survivors() -> void:
	if survivor_spawn < 0 or not survivor_alive or survivor_evacuated or baseball_spawn < 0 or not baseball_alive or baseball_evacuated:
		return
	var difference := baseball_position - survivor_position
	var distance := difference.length()
	var minimum_distance := SURVIVOR_COLLISION_RADIUS * 2.0
	if distance >= minimum_distance:
		return
	var direction := difference / distance if distance > 0.001 else Vector2.RIGHT
	var correction := direction * (minimum_distance - distance) * 0.5
	survivor_position -= correction
	baseball_position += correction

func _survivor_target_alive(target_id: String) -> bool:
	if target_id == "cop":
		return survivor_spawn >= 0 and survivor_alive and not survivor_evacuated
	if target_id == "baseball":
		return baseball_spawn >= 0 and baseball_alive and not baseball_evacuated
	return false

func _survivor_target_position(target_id: String) -> Vector2:
	return survivor_position if target_id == "cop" else baseball_position

func _damage_survivor_target(target_id: String) -> void:
	if target_id == "cop":
		survivor_health -= 1
		if survivor_health <= 0:
			_kill_survivor()
	elif target_id == "baseball":
		baseball_health -= 1
		if baseball_health <= 0:
			_kill_baseball_survivor()

func _kill_survivor() -> void:
	survivor_health = 0
	survivor_alive = false
	survivor_selected = false
	dragging_survivor = false
	survivor_is_walking = false
	for zombie in zombies:
		if zombie.target_id == "cop":
			zombie.target_id = ""

func _kill_baseball_survivor() -> void:
	baseball_health = 0
	baseball_alive = false
	baseball_selected = false
	dragging_survivor = false
	baseball_is_walking = false
	baseball_zone_move = false
	for zombie in zombies:
		if zombie.target_id == "baseball":
			zombie.target_id = ""

func _update_survivor(delta: float) -> void:
	if survivor_spawn < 0 or not survivor_alive or survivor_evacuated:
		return
	if survivor_retreating:
		survivor_target = _survivor_entry_position()
		survivor_is_walking = true
		var retreat_angle := survivor_position.angle_to_point(survivor_target)
		survivor_aim_angle = rotate_toward(survivor_aim_angle, retreat_angle, SURVIVOR_TURN_SPEED * delta)
		var retreat_speed := _survivor_travel_speed(survivor_position, SURVIVOR_SPEED)
		survivor_position = _move_around_car(survivor_position, survivor_target, retreat_speed * delta)
		if survivor_position.distance_to(survivor_target) <= 1.0:
			survivor_evacuated = true
			survivor_is_walking = false
			_clear_zombie_target("cop")
		return

	if is_reloading:
		reload_time_remaining -= delta
		if reload_time_remaining <= 0.0:
			is_reloading = false
			ammo = MAGAZINE_SIZE
		else:
			return

	survivor_target = _zone_home(survivor_spawn, "cop")
	var target := _closest_zombie()
	var distance_to_zombie := INF
	if not target.is_empty():
		var zombie_position := _zombie_position(target)
		distance_to_zombie = survivor_position.distance_to(zombie_position)
		survivor_target = _cop_cover_position(zombie_position)

	var zombie_in_range := distance_to_zombie <= _survivor_range()
	var zombie_in_awareness := distance_to_zombie <= _survivor_range() * SURVIVOR_AWARENESS_MULTIPLIER

	# Reload empty magazines immediately. Top off early only when nearby zombies
	# are not an immediate threat.
	if ammo <= 0 or (ammo <= EARLY_RELOAD_AT and not zombie_in_awareness):
		_start_reload()
		return
	if zombie_in_awareness:
		var desired_angle := survivor_position.angle_to_point(_zombie_position(target))
		survivor_aim_angle = rotate_toward(survivor_aim_angle, desired_angle, SURVIVOR_TURN_SPEED * delta)
	elif survivor_position.distance_to(survivor_target) > 1.0:
		var walk_angle := survivor_position.angle_to_point(survivor_target)
		survivor_aim_angle = rotate_toward(survivor_aim_angle, walk_angle, SURVIVOR_TURN_SPEED * delta)

	var distance_to_destination := survivor_position.distance_to(survivor_target)
	if zombie_in_range:
		fire_cooldown -= delta
		if fire_cooldown <= 0.0:
			_shoot(target)
		survivor_is_walking = distance_to_destination > 1.0
		if survivor_is_walking:
			var combat_speed := _survivor_travel_speed(survivor_position, SURVIVOR_COMBAT_SPEED)
			survivor_position = _move_around_car(
				survivor_position,
				survivor_target,
				combat_speed * delta
			)
	elif distance_to_destination > 1.0:
		survivor_is_walking = true
		var travel_speed := _survivor_travel_speed(survivor_position, SURVIVOR_SPEED)
		survivor_position = _move_around_car(survivor_position, survivor_target, travel_speed * delta)
	else:
		survivor_is_walking = false

func _cop_cover_position(zombie_position: Vector2) -> Vector2:
	var home := _zone_home(survivor_spawn, "cop")
	if survivor_spawn < 0:
		return home
	var safe_zone := _deployment_zones()[survivor_spawn].grow(-SURVIVOR_COLLISION_RADIUS)
	var best_position := home
	var best_score := INF
	for car_rect in _car_obstacle_rects(12.0):
		var center := car_rect.get_center()
		if not safe_zone.has_point(center):
			continue
		var away_from_zombie := zombie_position.direction_to(center)
		if away_from_zombie.is_zero_approx():
			away_from_zombie = Vector2.RIGHT
		var cover_distance := maxf(car_rect.size.x, car_rect.size.y) * 0.5 + SURVIVOR_COLLISION_RADIUS + 8.0
		var candidate := center + away_from_zombie * cover_distance
		candidate.x = clampf(candidate.x, safe_zone.position.x, safe_zone.end.x)
		candidate.y = clampf(candidate.y, safe_zone.position.y, safe_zone.end.y)
		if _zombie_position_blocked(candidate):
			continue
		var score := survivor_position.distance_to(candidate) + zombie_position.distance_to(candidate) * 0.08
		if score < best_score:
			best_score = score
			best_position = candidate
	return best_position

func _update_baseball_survivor(delta: float) -> void:
	if baseball_spawn < 0 or not baseball_alive or baseball_evacuated:
		return
	if baseball_retreating:
		baseball_target = _survivor_entry_position()
		baseball_is_walking = true
		var retreat_angle := baseball_position.angle_to_point(baseball_target)
		baseball_aim_angle = rotate_toward(baseball_aim_angle, retreat_angle, SURVIVOR_TURN_SPEED * delta)
		var retreat_speed := _survivor_travel_speed(baseball_position, BASEBALL_SPEED)
		baseball_position = _move_around_car(baseball_position, baseball_target, retreat_speed * delta)
		if baseball_position.distance_to(baseball_target) <= 1.0:
			baseball_evacuated = true
			baseball_is_walking = false
			_clear_zombie_target("baseball")
		return

	baseball_attack_cooldown -= delta
	baseball_swing_time = maxf(0.0, baseball_swing_time - delta)
	var zone := _deployment_zones()[baseball_spawn]
	var safe_zone := zone.grow(-SURVIVOR_COLLISION_RADIUS)

	# While transferring zones, keep advancing and bash anything physically
	# blocking the route. The move arrow disappears at the zone boundary.
	if not zone.has_point(baseball_position):
		baseball_target = _zone_home(baseball_spawn, "baseball")
		baseball_zone_move = true
		var blocking_zombie := _closest_zombie_to_baseball(BASEBALL_MELEE_METERS * TILE_SIZE)
		if not blocking_zombie.is_empty() and baseball_attack_cooldown <= 0.0:
			_swing_bat(blocking_zombie)
		var transfer_angle := baseball_position.angle_to_point(baseball_target)
		baseball_aim_angle = rotate_toward(baseball_aim_angle, transfer_angle, SURVIVOR_TURN_SPEED * delta)
		baseball_is_walking = true
		var transfer_speed := _survivor_travel_speed(baseball_position, BASEBALL_SPEED)
		baseball_position = _move_around_car(baseball_position, baseball_target, transfer_speed * delta)
		return

	baseball_zone_move = false
	var target := _closest_zombie_in_baseball_roam()
	if not target.is_empty():
		var target_position := _zombie_position(target)
		var desired_angle := baseball_position.angle_to_point(target_position)
		baseball_aim_angle = rotate_toward(baseball_aim_angle, desired_angle, SURVIVOR_TURN_SPEED * delta)
		var distance := baseball_position.distance_to(target_position)
		if baseball_attack_cooldown > 0.0:
			var wait_distance := BASEBALL_WAIT_DISTANCE_METERS * TILE_SIZE
			if distance < wait_distance:
				baseball_is_walking = true
				var retreat_direction := target_position.direction_to(baseball_position)
				var next_position := baseball_position + retreat_direction * BASEBALL_RECHARGE_SPEED * delta
				if _point_in_deployment_zone(next_position, baseball_spawn):
					baseball_position = _move_around_car(baseball_position, next_position, BASEBALL_RECHARGE_SPEED * delta)
			else:
				baseball_is_walking = false
		elif distance <= BASEBALL_MELEE_METERS * TILE_SIZE:
			baseball_is_walking = false
			_swing_bat(target)
		else:
			baseball_is_walking = true
			var chase_speed := _survivor_travel_speed(baseball_position, BASEBALL_SPEED)
			baseball_position = _move_around_car(baseball_position, target_position, chase_speed * delta)
	else:
		var nearest_zombie := _closest_zombie_to_baseball()
		if not nearest_zombie.is_empty():
			baseball_target = _zone_edge_toward(_zombie_position(nearest_zombie), safe_zone)
			baseball_patrol_timer = 0.0
		else:
			baseball_patrol_timer -= delta
			if baseball_patrol_target == Vector2.ZERO or baseball_position.distance_to(baseball_patrol_target) <= 8.0 or baseball_patrol_timer <= 0.0:
				baseball_patrol_target = _random_patrol_point(safe_zone)
				baseball_patrol_timer = randf_range(2.5, 5.0)
			baseball_target = baseball_patrol_target

		if baseball_position.distance_to(baseball_target) > 8.0:
			baseball_is_walking = true
			var patrol_angle := baseball_position.angle_to_point(baseball_target)
			baseball_aim_angle = rotate_toward(baseball_aim_angle, patrol_angle, SURVIVOR_TURN_SPEED * delta)
			baseball_position = _move_around_car(baseball_position, baseball_target, BASEBALL_RECHARGE_SPEED * delta)
		else:
			baseball_is_walking = false

func _closest_zombie_to_baseball(max_distance: float = INF) -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance := max_distance
	for zombie in zombies:
		var distance := baseball_position.distance_to(_zombie_position(zombie))
		if distance <= closest_distance:
			closest = zombie
			closest_distance = distance
	return closest

func _zone_edge_toward(point: Vector2, zone: Rect2) -> Vector2:
	return Vector2(
		clampf(point.x, zone.position.x, zone.end.x),
		clampf(point.y, zone.position.y, zone.end.y)
	)

func _random_patrol_point(zone: Rect2) -> Vector2:
	var car_clearance := _car_rect().grow(30.0)
	for attempt in 8:
		var point := Vector2(
			randf_range(zone.position.x, zone.end.x),
			randf_range(zone.position.y, zone.end.y)
		)
		if not car_clearance.has_point(point):
			return point
	return zone.position + Vector2(36.0, 36.0)

func _cars() -> Array[Dictionary]:
	return [
		{"center": Vector2(603, 678), "size": Vector2(96, 177), "rotation": PI * 0.5},
		{"center": Vector2(245, 390), "size": Vector2(96, 177), "rotation": -0.22},
		{"center": Vector2(650, 335), "size": Vector2(96, 177), "rotation": 0.12},
		{"center": Vector2(1030, 900), "size": Vector2(96, 177), "rotation": PI * 0.5 + 0.18}
	]

func _rotated_car_rect(car: Dictionary) -> Rect2:
	var car_size: Vector2 = car.size
	var angle: float = car.rotation
	var extent := Vector2(
		absf(cos(angle)) * car_size.x + absf(sin(angle)) * car_size.y,
		absf(sin(angle)) * car_size.x + absf(cos(angle)) * car_size.y
	) * 0.5
	var center: Vector2 = car.center
	return Rect2(center - extent, extent * 2.0)

func _car_obstacle_rects(grow_by: float = 0.0) -> Array[Rect2]:
	var obstacles: Array[Rect2] = []
	for car in _cars():
		obstacles.append(_rotated_car_rect(car).grow(grow_by))
	return obstacles

func _car_rect() -> Rect2:
	return _rotated_car_rect(_cars()[0])

func _house_rect() -> Rect2:
	return Rect2(Vector2(875, 42), Vector2(330, 250))

func _survivor_travel_speed(position: Vector2, base_speed: float) -> float:
	# Only fast-travel while fully off-screen. Using the viewport instead of the
	# map boundary keeps zooming and panning from exposing a boosted survivor.
	var screen_position := _map_to_screen(position)
	var visible_area := Rect2(Vector2(-64.0, -64.0), size + Vector2(128.0, 128.0))
	return base_speed * OFF_MAP_SURVIVOR_SPEED_MULTIPLIER if not visible_area.has_point(screen_position) else base_speed

func _clear_zombie_target(target_id: String) -> void:
	for zombie in zombies:
		if String(zombie.target_id) == target_id:
			zombie.target_id = ""

func _segment_intersects_rect(from: Vector2, to: Vector2, rect: Rect2) -> bool:
	if rect.has_point(from) or rect.has_point(to):
		return true
	var top_left := rect.position
	var top_right := Vector2(rect.end.x, rect.position.y)
	var bottom_right := rect.end
	var bottom_left := Vector2(rect.position.x, rect.end.y)
	return (
		Geometry2D.segment_intersects_segment(from, to, top_left, top_right) != null
		or Geometry2D.segment_intersects_segment(from, to, top_right, bottom_right) != null
		or Geometry2D.segment_intersects_segment(from, to, bottom_right, bottom_left) != null
		or Geometry2D.segment_intersects_segment(from, to, bottom_left, top_left) != null
	)

func _move_around_car(current: Vector2, target: Vector2, distance: float) -> Vector2:
	# Route around whichever solid obstacle is encountered first. Keeping this
	# in the shared movement helper makes both survivors respect the house.
	var obstacles := _car_obstacle_rects(30.0)
	obstacles.append(_house_rect().grow(24.0))
	var obstacle := Rect2()
	var obstacle_found := false
	var nearest_obstacle_distance := INF
	for candidate in obstacles:
		if candidate.has_point(current):
			obstacle = candidate
			obstacle_found = true
			break
		if not _segment_intersects_rect(current, target, candidate):
			continue
		var candidate_distance := current.distance_to(candidate.get_center())
		if candidate_distance < nearest_obstacle_distance:
			nearest_obstacle_distance = candidate_distance
			obstacle = candidate
			obstacle_found = true
	if not obstacle_found:
		return current.move_toward(target, distance)

	# Unit separation can occasionally shove a survivor just inside an
	# obstacle's clearance box. Recover before calculating waypoints.
	if obstacle.has_point(current):
		var left_distance := current.x - obstacle.position.x
		var right_distance := obstacle.end.x - current.x
		var top_distance := current.y - obstacle.position.y
		var bottom_distance := obstacle.end.y - current.y
		var nearest := minf(minf(left_distance, right_distance), minf(top_distance, bottom_distance))
		if nearest == left_distance:
			current.x = obstacle.position.x - 1.0
		elif nearest == right_distance:
			current.x = obstacle.end.x + 1.0
		elif nearest == top_distance:
			current.y = obstacle.position.y - 1.0
		else:
			current.y = obstacle.end.y + 1.0
	if not _segment_intersects_rect(current, target, obstacle):
		return current.move_toward(target, distance)

	# Find a complete clear route, including the second corner when the target is
	# across the car. This prevents a unit from repeatedly choosing the corner it
	# has already reached and becoming pinned there.
	var clearance := 8.0
	var waypoints: Array[Vector2] = [
		obstacle.position - Vector2(clearance, clearance),
		Vector2(obstacle.end.x + clearance, obstacle.position.y - clearance),
		Vector2(obstacle.position.x - clearance, obstacle.end.y + clearance),
		obstacle.end + Vector2(clearance, clearance)
	]
	var best_first := Vector2.ZERO
	var best_distance := INF

	# A single corner is enough when it has clear sight to both endpoints.
	for waypoint in waypoints:
		if current.distance_to(waypoint) <= 1.0:
			continue
		if _segment_intersects_rect(current, waypoint, obstacle):
			continue
		if _segment_intersects_rect(waypoint, target, obstacle):
			continue
		var route_distance := current.distance_to(waypoint) + waypoint.distance_to(target)
		if route_distance < best_distance:
			best_distance = route_distance
			best_first = waypoint

	# Targets on the opposite side require travelling around two adjacent
	# corners. If the first corner was already reached, advance to the second.
	for first in waypoints:
		for second in waypoints:
			if first == second:
				continue
			if _segment_intersects_rect(first, second, obstacle):
				continue
			if _segment_intersects_rect(second, target, obstacle):
				continue
			var first_leg := current
			var next_waypoint := first
			if current.distance_to(first) <= 1.0:
				next_waypoint = second
			else:
				if _segment_intersects_rect(current, first, obstacle):
					continue
				first_leg = first
			if next_waypoint == second and _segment_intersects_rect(current, second, obstacle):
				continue
			var route_distance := current.distance_to(first_leg)
			route_distance += first.distance_to(second)
			route_distance += second.distance_to(target)
			if route_distance < best_distance:
				best_distance = route_distance
				best_first = next_waypoint

	if best_distance == INF:
		return current
	return current.move_toward(best_first, distance)

func _closest_zombie_in_baseball_roam() -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance := INF
	for zombie in zombies:
		var zombie_position := _zombie_position(zombie)
		if not _point_in_deployment_zone(zombie_position, baseball_spawn):
			continue
		var distance := baseball_position.distance_to(zombie_position)
		if distance < closest_distance:
			closest = zombie
			closest_distance = distance
	return closest

func _swing_bat(target: Dictionary) -> void:
	if target.is_empty() or not zombies.has(target):
		return
	baseball_attack_cooldown = BASEBALL_ATTACK_RATE
	baseball_swing_time = BASEBALL_SWING_DURATION
	var hit_zombies: Array[Dictionary] = []
	for zombie in zombies:
		if baseball_position.distance_to(_zombie_position(zombie)) <= BASEBALL_AOE_METERS * TILE_SIZE:
			hit_zombies.append(zombie)

	for zombie in hit_zombies:
		var target_position := _zombie_position(zombie)
		if String(zombie.target_id) == "":
			zombie.target_id = "baseball"
		var knockback_direction := baseball_position.direction_to(target_position)
		zombie.knockback_velocity = knockback_direction * BASEBALL_KNOCKBACK_SPEED
		zombie.movement_factor = 0.02
		zombie.hp -= _baseball_damage()
		for i in 4:
			var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
			blood_particles.append({
				"position": target_position + direction * randf_range(2.0, 7.0),
				"velocity": direction * randf_range(15.0, 45.0),
				"life": BLOOD_PARTICLE_LIFE * randf_range(0.55, 0.85)
			})
		if zombie.hp <= 0 and zombies.has(zombie):
			zombies.erase(zombie)
			zombies_killed += 1
			baseball_kills += 1
			_award_baseball_xp()

	# The impact can also draw nearby, untargeted zombies toward the batter.
	var hearing_range := GUNSHOT_HEARING_RANGE_METERS * TILE_SIZE
	for zombie in zombies:
		if String(zombie.target_id) != "":
			continue
		if _zombie_position(zombie).distance_to(baseball_position) <= hearing_range:
			if randf() <= GUNSHOT_RETARGET_CHANCE:
				zombie.target_id = "baseball"

func _baseball_damage() -> float:
	return BASEBALL_DAMAGE + (baseball_level - 1) * BASEBALL_DAMAGE_PER_LEVEL

func _closest_zombie() -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance := INF
	for zombie in zombies:
		var distance := survivor_position.distance_to(_zombie_position(zombie))
		if distance < closest_distance:
			closest = zombie
			closest_distance = distance
	return closest

func _start_reload() -> void:
	if is_reloading or ammo >= MAGAZINE_SIZE:
		return
	is_reloading = true
	reload_time_remaining = RELOAD_TIME

func _shoot(target: Dictionary) -> void:
	if target.is_empty() or not zombies.has(target) or is_reloading or ammo <= 0:
		return

	var intended_direction := survivor_position.direction_to(_zombie_position(target))
	var max_spread := deg_to_rad(COP_MAX_SPREAD_DEGREES) * (1.0 - COP_ACCURACY)
	var shot_direction := intended_direction.rotated(randf_range(-max_spread, max_spread))
	var ray_length := _survivor_range()
	var ray_end := survivor_position + shot_direction * ray_length
	var hit_zombie: Dictionary = {}
	var hit_distance := INF

	# Find the first zombie whose body intersects the finite shot ray.
	for zombie in zombies:
		var offset := _zombie_position(zombie) - survivor_position
		var distance_along_ray := offset.dot(shot_direction)
		if distance_along_ray < 0.0 or distance_along_ray > ray_length:
			continue
		var closest_point := survivor_position + shot_direction * distance_along_ray
		if closest_point.distance_to(_zombie_position(zombie)) <= ZOMBIE_HIT_RADIUS:
			if distance_along_ray < hit_distance:
				hit_distance = distance_along_ray
				hit_zombie = zombie

	var impact_position := ray_end
	if not hit_zombie.is_empty():
		impact_position = survivor_position + shot_direction * hit_distance
	shots.append({"start":survivor_position, "end":impact_position, "life":0.12})
	ammo -= 1
	fire_cooldown = FIRE_RATE

	if not hit_zombie.is_empty():
		var zombie_position := _zombie_position(hit_zombie)
		for i in 7:
			var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
			blood_particles.append({
				"position": zombie_position + direction * randf_range(2.0, 8.0),
				"velocity": direction * randf_range(20.0, 65.0),
				"life": BLOOD_PARTICLE_LIFE * randf_range(0.65, 1.0)
			})
		if String(hit_zombie.target_id) == "":
			hit_zombie.target_id = "cop"
		var knockback_direction := survivor_position.direction_to(zombie_position)
		var knocked_position := zombie_position + knockback_direction * ZOMBIE_HIT_KNOCKBACK
		hit_zombie.x = knocked_position.x / _map_size().x
		hit_zombie.y = knocked_position.y
		hit_zombie.movement_factor = 0.08
		hit_zombie.hp -= 1
		if hit_zombie.hp <= 0:
			zombies.erase(hit_zombie)
			zombies_killed += 1
			cop_kills += 1
			_award_cop_xp()

	# Nearby untargeted zombies can react to the sound even when the shot misses.
	var hearing_range := GUNSHOT_HEARING_RANGE_METERS * TILE_SIZE
	for zombie in zombies:
		if zombie == hit_zombie or String(zombie.target_id) != "":
			continue
		if _zombie_position(zombie).distance_to(survivor_position) <= hearing_range:
			if randf() <= GUNSHOT_RETARGET_CHANCE:
				zombie.target_id = "cop"

func _award_cop_xp() -> void:
	cop_xp += 1
	if cop_xp >= cop_xp_to_next:
		cop_xp -= cop_xp_to_next
		cop_level += 1
		cop_xp_to_next = cop_level * 3
		survivor_max_health += 2
		survivor_health = survivor_max_health
		level_up_effects.append({"unit":"cop", "life":LEVEL_UP_EFFECT_LIFE})

func _award_baseball_xp() -> void:
	baseball_xp += 1
	if baseball_xp >= baseball_xp_to_next:
		baseball_xp -= baseball_xp_to_next
		baseball_level += 1
		baseball_xp_to_next = baseball_level * 3
		baseball_max_health += 2
		baseball_health = baseball_max_health
		level_up_effects.append({"unit":"baseball", "life":LEVEL_UP_EFFECT_LIFE})

func _start_game() -> void:
	screen = "playing"
	_layout_ui()
	health = STARTING_HEALTH
	zombies_passed = 0
	zombies_killed = 0
	zombies.clear()
	wave = 0
	zombies_left_to_spawn = 0
	wave_delay = 0.5
	spawn_delay = 0.0
	survivor_spawn = -1
	survivor_max_health = SURVIVOR_MAX_HEALTH
	cop_level = 1
	cop_xp = 0
	cop_xp_to_next = 3
	cop_kills = 0
	baseball_spawn = -1
	baseball_max_health = BASEBALL_MAX_HEALTH
	baseball_level = 1
	baseball_xp = 0
	baseball_xp_to_next = 3
	baseball_health = BASEBALL_MAX_HEALTH
	baseball_alive = true
	baseball_selected = false
	baseball_position = Vector2.ZERO
	baseball_target = Vector2.ZERO
	baseball_is_walking = false
	baseball_zone_move = false
	baseball_patrol_target = Vector2.ZERO
	baseball_patrol_timer = 0.0
	baseball_retreating = false
	baseball_evacuated = false
	baseball_aim_angle = PI
	baseball_attack_cooldown = 0.0
	baseball_swing_time = 0.0
	baseball_kills = 0
	dragging_unit = ""
	survivor_health = SURVIVOR_MAX_HEALTH
	survivor_alive = true
	survivor_selected = false
	dragging_survivor = false
	fire_cooldown = 0.0
	ammo = MAGAZINE_SIZE
	reload_time_remaining = 0.0
	is_reloading = false
	survivor_aim_angle = PI
	survivor_retreating = false
	survivor_evacuated = false
	shots.clear()
	blood_particles.clear()
	level_up_effects.clear()
	map_zoom = 1.0
	map_offset = _centered_map_offset()
	map_dragging = false
	active_touches.clear()
	game_paused = false
	fast_forward = false
	pause_button.text = "PAUSE"
	fast_forward_button.text = "FF"
	retreat_button.disabled = false
	title_label.hide()
	results_label.hide()
	begin_button.hide()
	map_button.hide()
	start_map_button.hide()
	selection_back_button.hide()
	retry_button.hide()
	menu_button.hide()
	pause_button.show()
	fast_forward_button.show()
	retreat_button.show()
	health_label.show()
	queue_redraw()

func _show_menu() -> void:
	screen = "menu"
	_layout_ui()
	title_label.text = "ZOMBIE DEFENSE"
	title_label.show()
	health_label.hide()
	results_label.hide()
	begin_button.show()
	map_button.hide()
	start_map_button.hide()
	selection_back_button.hide()
	retry_button.hide()
	menu_button.hide()
	pause_button.hide()
	fast_forward_button.hide()
	retreat_button.hide()
	queue_redraw()

func _show_results() -> void:
	screen = "results"
	_layout_ui()
	health_label.hide()
	title_label.show()
	title_label.text = "THE TOWN FELL"
	results_label.text = "Reached wave %d\n%d zombies killed" % [wave, zombies_killed]
	results_label.show()
	begin_button.hide()
	map_button.hide()
	start_map_button.hide()
	selection_back_button.hide()
	retry_button.show()
	menu_button.show()
	pause_button.hide()
	fast_forward_button.hide()
	retreat_button.hide()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if screen != "playing":
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton or event is InputEventMouseMotion:
		if pause_button.get_global_rect().has_point(event.position) or fast_forward_button.get_global_rect().has_point(event.position) or retreat_button.get_global_rect().has_point(event.position):
			return

	if event is InputEventScreenTouch:
		if event.pressed:
			active_touches[event.index] = event.position
			if active_touches.size() == 1:
				pointer_down_position = event.position
				map_dragging = not _handle_pointer_down(event.position)
				map_drag_position = event.position
			elif active_touches.size() == 2:
				map_dragging = false
				dragging_survivor = false
				dragging_unit = ""
				pinch_distance = _touch_distance()
		else:
			if active_touches.size() == 1:
				if dragging_survivor:
					_handle_pointer_up(event.position)
				elif map_dragging:
					_handle_map_pointer_up(event.position)
			active_touches.erase(event.index)
			if active_touches.size() < 2:
				pinch_distance = 0.0
			if active_touches.is_empty():
				map_dragging = false
			elif active_touches.size() == 1:
				map_drag_position = active_touches.values()[0]
	elif event is InputEventScreenDrag:
		active_touches[event.index] = event.position
		if active_touches.size() >= 2:
			var new_distance := _touch_distance()
			if pinch_distance > 0.0:
				_zoom_at(_touch_center(), map_zoom * new_distance / pinch_distance)
			pinch_distance = new_distance
		elif dragging_survivor:
			drag_position = event.position
		elif map_dragging:
			_pan_map(event.position - map_drag_position)
			map_drag_position = event.position
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.position, map_zoom * 1.12)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.position, map_zoom / 1.12)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				pointer_down_position = event.position
				map_dragging = not _handle_pointer_down(event.position)
				map_drag_position = event.position
			else:
				if dragging_survivor:
					_handle_pointer_up(event.position)
				elif map_dragging:
					_handle_map_pointer_up(event.position)
				map_dragging = false
	elif event is InputEventMouseMotion:
		if dragging_survivor:
			drag_position = event.position
		elif map_dragging:
			_pan_map(event.position - map_drag_position)
			map_drag_position = event.position
		queue_redraw()

func _touch_distance() -> float:
	var touches := active_touches.values()
	return touches[0].distance_to(touches[1])

func _touch_center() -> Vector2:
	var touches := active_touches.values()
	return (touches[0] + touches[1]) * 0.5

func _zoom_at(screen_position: Vector2, new_zoom: float) -> void:
	var map_position := _screen_to_map(screen_position)
	map_zoom = clampf(new_zoom, _minimum_zoom(), 2.0)
	map_offset = screen_position - map_position * map_zoom
	queue_redraw()

func _pan_map(delta: Vector2) -> void:
	var bounds := _map_offset_bounds()
	var adjusted := delta
	if (map_offset.x > bounds.max_x and delta.x > 0.0) or (map_offset.x < bounds.min_x and delta.x < 0.0):
		adjusted.x *= OVERSCROLL_RESISTANCE
	if (map_offset.y > bounds.max_y and delta.y > 0.0) or (map_offset.y < bounds.min_y and delta.y < 0.0):
		adjusted.y *= OVERSCROLL_RESISTANCE
	map_offset += adjusted
	# The overscan is the hard edge: resistance begins at the soft bounds,
	# but dragging can continue until the extended terrain reaches the viewport.
	var hard_min := Vector2(
		size.x - (_map_size().x + MAP_OVERSCAN) * map_zoom,
		size.y - (_map_size().y + MAP_OVERSCAN) * map_zoom
	)
	var hard_max := Vector2(MAP_OVERSCAN * map_zoom, MAP_OVERSCAN * map_zoom)
	map_offset.x = clampf(map_offset.x, hard_min.x, hard_max.x)
	map_offset.y = clampf(map_offset.y, hard_min.y, hard_max.y)

func _minimum_zoom() -> float:
	var playable_height := maxf(1.0, size.y - 190.0)
	var map_size := _map_size()
	return maxf(size.x / map_size.x, playable_height / map_size.y) * 0.70

func _map_offset_bounds() -> Dictionary:
	var map_size := _map_size() * map_zoom
	var top := 78.0
	var bottom := size.y - 112.0
	var points := _spawn_points()
	var leftmost_node_x := points[0].x
	var rightmost_node_x := points[0].x
	var topmost_node_y := points[0].y
	var bottommost_node_y := points[0].y
	for point in points:
		leftmost_node_x = minf(leftmost_node_x, point.x)
		rightmost_node_x = maxf(rightmost_node_x, point.x)
		topmost_node_y = minf(topmost_node_y, point.y)
		bottommost_node_y = maxf(bottommost_node_y, point.y)
	# Let the outer placement nodes travel across most of the viewport before
	# reaching the soft edge, rather than stopping at the map boundary.
	var min_x := size.x * CAMERA_NODE_EDGE_RATIO - rightmost_node_x * map_zoom
	var max_x := size.x * (1.0 - CAMERA_NODE_EDGE_RATIO) - leftmost_node_x * map_zoom
	var playable_height := bottom - top
	var min_y := top + playable_height * CAMERA_NODE_EDGE_RATIO - bottommost_node_y * map_zoom
	var max_y := top + playable_height * (1.0 - CAMERA_NODE_EDGE_RATIO) - topmost_node_y * map_zoom
	if min_x > max_x:
		min_x = (size.x - map_size.x) * 0.5
		max_x = min_x
	if min_y > max_y:
		min_y = top + (bottom - top - map_size.y) * 0.5
		max_y = min_y
	return {"min_x":min_x, "max_x":max_x, "min_y":min_y, "max_y":max_y}

func _clamped_map_offset(offset: Vector2) -> Vector2:
	var bounds := _map_offset_bounds()
	return Vector2(
		clampf(offset.x, bounds.min_x, bounds.max_x),
		clampf(offset.y, bounds.min_y, bounds.max_y)
	)

func _centered_map_offset() -> Vector2:
	var map_pixels := _map_size() * map_zoom
	var top := 78.0
	var bottom := size.y - 112.0
	return _clamped_map_offset(Vector2(
		(size.x - map_pixels.x) * 0.5,
		top + (bottom - top - map_pixels.y) * 0.5
	))

func _map_to_screen(map_position: Vector2) -> Vector2:
	return map_position * map_zoom + map_offset

func _screen_to_map(screen_position: Vector2) -> Vector2:
	return (screen_position - map_offset) / map_zoom

func _handle_pointer_down(position: Vector2) -> bool:
	if (survivor_selected or baseball_selected) and _survivor_info_close_rect().has_point(position):
		survivor_selected = false
		baseball_selected = false
		dragging_survivor = false
		dragging_unit = ""
		queue_redraw()
		return true
	var touched_cop := (
		(survivor_spawn < 0 and _survivor_card_rect().has_point(position))
		or (survivor_spawn >= 0 and survivor_alive and not survivor_retreating and not survivor_evacuated and _map_to_screen(survivor_position).distance_to(position) <= 42.0)
	)
	var touched_baseball := (
		(baseball_spawn < 0 and _baseball_card_rect().has_point(position))
		or (baseball_spawn >= 0 and baseball_alive and not baseball_retreating and not baseball_evacuated and _map_to_screen(baseball_position).distance_to(position) <= 42.0)
	)
	if touched_cop or touched_baseball:
		dragging_unit = "cop" if touched_cop else "baseball"
		survivor_selected = touched_cop
		baseball_selected = touched_baseball
		dragging_survivor = true
		drag_position = position
		pointer_down_position = position
		queue_redraw()
		return true
	# Map taps are resolved on release. This lets a selected survivor coexist
	# with a pan gesture without assigning the zone touched at drag start.
	return false

func _handle_map_pointer_up(position: Vector2) -> void:
	if pointer_down_position.distance_to(position) > 10.0:
		return
	if not survivor_selected and not baseball_selected:
		return
	var index := _spawn_point_at(position)
	if index >= 0:
		_set_selected_survivor_destination(index)
	else:
		survivor_selected = false
		baseball_selected = false
		dragging_unit = ""
		queue_redraw()

func _handle_pointer_up(position: Vector2) -> void:
	if not dragging_survivor:
		return
	dragging_survivor = false
	if pointer_down_position.distance_to(position) > 10.0:
		var index := _spawn_point_at(position)
		if index >= 0:
			_set_selected_survivor_destination(index)
	dragging_unit = ""
	queue_redraw()

func _set_selected_survivor_destination(index: int) -> void:
	if survivor_selected:
		if survivor_spawn < 0:
			_place_survivor(index)
		elif survivor_spawn == index:
			survivor_selected = false
		else:
			survivor_spawn = index
			survivor_target = _zone_home(index, "cop")
			survivor_is_walking = survivor_position.distance_to(survivor_target) > 1.0
			survivor_selected = false
	elif baseball_selected:
		if baseball_spawn < 0:
			_place_baseball_survivor(index)
		elif baseball_spawn == index:
			baseball_selected = false
		else:
			baseball_spawn = index
			baseball_target = _zone_home(index, "baseball")
			baseball_zone_move = true
			baseball_patrol_target = Vector2.ZERO
			baseball_patrol_timer = 0.0
			baseball_selected = false
	dragging_survivor = false
	dragging_unit = ""
	queue_redraw()

func _place_survivor(index: int) -> void:
	survivor_spawn = index
	survivor_target = _zone_home(index, "cop")
	survivor_position = _survivor_entry_position()
	survivor_aim_angle = PI
	survivor_is_walking = true
	survivor_selected = false
	dragging_survivor = false
	fire_cooldown = 0.0

func _place_baseball_survivor(index: int) -> void:
	baseball_spawn = index
	baseball_target = _zone_home(index, "baseball")
	baseball_position = _survivor_entry_position()
	baseball_aim_angle = PI
	baseball_is_walking = true
	baseball_zone_move = true
	baseball_patrol_target = Vector2.ZERO
	baseball_patrol_timer = 0.0
	baseball_selected = false
	dragging_survivor = false
	baseball_attack_cooldown = 0.0

func _spawn_point_at(position: Vector2) -> int:
	position = _screen_to_map(position)
	var zones := _deployment_zones()
	for i in zones.size():
		if zones[i].has_point(position):
			return i
	return -1

func _map_size() -> Vector2:
	var side := MAP_SIZE_TILES * TILE_SIZE
	return Vector2(side, side)

func _field_rect() -> Rect2:
	return Rect2(Vector2.ZERO, _map_size())

func _main_road_x() -> float:
	return TILE_SIZE * 10.0

func _upper_road_y() -> float:
	return TILE_SIZE * 6.0

func _lower_road_y() -> float:
	return TILE_SIZE * 14.0

func _route_exit_x() -> float:
	return _map_size().x + MAP_OVERSCAN + TILE_SIZE

func _road_rect() -> Rect2:
	var half_width := STREET_WIDTH_TILES * TILE_SIZE * 0.5
	return Rect2(
		-MAP_OVERSCAN,
		_upper_road_y() - half_width,
		_main_road_x() + half_width + MAP_OVERSCAN,
		half_width * 2.0
	)

func _right_road_rect() -> Rect2:
	var half_width := STREET_WIDTH_TILES * TILE_SIZE * 0.5
	return Rect2(
		_main_road_x() - half_width,
		_lower_road_y() - half_width,
		_map_size().x - _main_road_x() + half_width + MAP_OVERSCAN,
		half_width * 2.0
	)

func _vertical_road_rect() -> Rect2:
	var half_width := STREET_WIDTH_TILES * TILE_SIZE * 0.5
	return Rect2(
		_main_road_x() - half_width,
		-MAP_OVERSCAN,
		half_width * 2.0,
		_map_size().y + MAP_OVERSCAN * 2.0
	)

func _sidewalk_rects() -> Array[Rect2]:
	var left_road := _road_rect()
	var right_road := _right_road_rect()
	var vertical := _vertical_road_rect()
	var sidewalk := SIDEWALK_WIDTH_TILES * TILE_SIZE
	var half_width := STREET_WIDTH_TILES * TILE_SIZE * 0.5
	var upper_top := _upper_road_y() - half_width
	var upper_bottom := _upper_road_y() + half_width
	var lower_top := _lower_road_y() - half_width
	var lower_bottom := _lower_road_y() + half_width
	return [
		Rect2(left_road.position.x, upper_top - sidewalk, vertical.position.x - left_road.position.x, sidewalk),
		Rect2(left_road.position.x, upper_bottom, vertical.position.x - left_road.position.x, sidewalk),
		Rect2(vertical.end.x, lower_top - sidewalk, right_road.end.x - vertical.end.x, sidewalk),
		Rect2(vertical.end.x, lower_bottom, right_road.end.x - vertical.end.x, sidewalk),
		# The west curb only opens for the upper road. It remains continuous
		# through the lower east-facing intersection.
		Rect2(vertical.position.x - sidewalk, vertical.position.y, sidewalk, upper_top - vertical.position.y),
		Rect2(vertical.position.x - sidewalk, upper_bottom, sidewalk, vertical.end.y - upper_bottom),
		# The east curb stays continuous through the upper west-facing
		# intersection, and only opens where the lower road branches east.
		Rect2(vertical.end.x, vertical.position.y, sidewalk, lower_top - vertical.position.y),
		Rect2(vertical.end.x, lower_bottom, sidewalk, vertical.end.y - lower_bottom)
	]

func _survivor_entry_position() -> Vector2:
	return Vector2(_route_exit_x(), _lower_road_y())

func _spawn_points() -> Array[Vector2]:
	var centers: Array[Vector2] = []
	for zone in _deployment_zones():
		centers.append(zone.get_center())
	return centers

func _deployment_zones() -> Array[Rect2]:
	return [
		Rect2(Vector2(64, 64), Vector2(320, 512)),
		Rect2(Vector2(384, 64), Vector2(448, 512)),
		Rect2(Vector2(832, 64), Vector2(384, 512)),
		Rect2(Vector2(64, 576), Vector2(320, 640)),
		Rect2(Vector2(384, 576), Vector2(448, 640)),
		Rect2(Vector2(832, 576), Vector2(384, 640))
	]

func _zone_home(index: int, unit: String) -> Vector2:
	var cop_homes: Array[Vector2] = [
		Vector2(165, 135), Vector2(500, 130), Vector2(910, 410),
		Vector2(155, 690), Vector2(500, 825), Vector2(920, 780)
	]
	var baseball_homes: Array[Vector2] = [
		Vector2(315, 155), Vector2(720, 150), Vector2(1115, 420),
		Vector2(315, 795), Vector2(710, 820), Vector2(1110, 1010)
	]
	return cop_homes[index] if unit == "cop" else baseball_homes[index]

func _point_in_deployment_zone(point: Vector2, index: int, padding: float = 0.0) -> bool:
	if index < 0:
		return false
	return _deployment_zones()[index].grow(padding).has_point(point)

func _survivor_card_rect() -> Rect2:
	return Rect2(size.x * 0.5 - 112, size.y - 105, 104, 92)

func _baseball_card_rect() -> Rect2:
	return Rect2(size.x * 0.5 + 8, size.y - 105, 104, 92)

func _zombie_position(zombie: Dictionary) -> Vector2:
	return Vector2(zombie.x * _map_size().x, zombie.y)

func _survivor_range() -> float:
	return SURVIVOR_RANGE_METERS * TILE_SIZE

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#111812"))
	if screen == "map_preview":
		_draw_map_preview()
		return
	if screen != "playing":
		return

	var map_size := _map_size()
	var terrain_extent := Rect2(
		Vector2(-MAP_OVERSCAN, -MAP_OVERSCAN),
		map_size + Vector2.ONE * MAP_OVERSCAN * 2.0
	)
	var left_road := _road_rect()
	var right_road := _right_road_rect()
	var vertical_road := _vertical_road_rect()

	# Draw in map space so Kenney's 64 px tiles zoom and pan with the world.
	draw_set_transform(map_offset, 0.0, Vector2(map_zoom, map_zoom))
	draw_texture_rect(GRASS_TEXTURE, terrain_extent, true)
	var asphalt_color := Color("#4b4b4b")
	draw_rect(left_road, asphalt_color)
	draw_rect(vertical_road, asphalt_color)
	draw_rect(right_road, asphalt_color)
	for sidewalk in _sidewalk_rects():
		draw_texture_rect(SIDEWALK_TEXTURE, sidewalk, true)
	_draw_decor()
	draw_set_transform(Vector2.ZERO, 0.0)

	# The road and sidewalks extend through the overscan past both soft bounds,
	# so dragging beyond an edge still looks like the street continues.

	if survivor_selected or baseball_selected:
		var zones := _deployment_zones()
		for i in zones.size():
			var polygon := _zone_screen_polygon(zones[i])
			var assigned := i == survivor_spawn or i == baseball_spawn
			var zone_color := Color("#62a8d8") if assigned else Color("#e8be4d")
			draw_colored_polygon(polygon, Color(zone_color, 0.22))
			var outline := polygon.duplicate()
			outline.append(polygon[0])
			draw_polyline(outline, Color(zone_color, 0.78), 3.0)
			var label_position := _map_to_screen(zones[i].get_center()) + Vector2(-36, 6)
			draw_string(ThemeDB.fallback_font, label_position, "ZONE %d" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, 72, 15, Color(zone_color, 0.95))

	if survivor_spawn >= 0 and not survivor_evacuated:
		var survivor_screen := _map_to_screen(survivor_position)
		if survivor_alive and survivor_is_walking:
			var destination_screen := _map_to_screen(survivor_target)
			var arrow_direction := survivor_screen.direction_to(destination_screen)
			var arrow_tip := destination_screen
			var arrow_base := arrow_tip - arrow_direction * 18.0
			var arrow_side := arrow_direction.orthogonal() * 9.0
			var arrow_color := Color(0.20, 0.65, 1.0, 0.58)
			draw_line(survivor_screen, arrow_base, arrow_color, 4.0)
			draw_colored_polygon(
				PackedVector2Array([arrow_tip, arrow_base + arrow_side, arrow_base - arrow_side]),
				arrow_color
			)
			draw_circle(destination_screen, 11.0, Color(0.20, 0.65, 1.0, 0.22))
			draw_arc(destination_screen, 11.0, 0.0, TAU, 24, arrow_color, 2.0)
		if survivor_alive and survivor_selected:
			draw_circle(survivor_screen, _survivor_range() * map_zoom, Color(0.45, 0.72, 0.48, 0.08))
			draw_arc(survivor_screen, _survivor_range() * map_zoom, 0, TAU, 48, Color(0.45, 0.72, 0.48, 0.25), 2)
		draw_set_transform(survivor_screen, survivor_aim_angle, Vector2(map_zoom, map_zoom))
		var survivor_color := Color.WHITE if survivor_alive else Color(0.35, 0.35, 0.35, 1.0)
		draw_texture_rect(SURVIVOR_TEXTURE, Rect2(Vector2(-38, -32), Vector2(76, 64)), false, survivor_color)
		draw_set_transform(Vector2.ZERO, 0.0)
		var survivor_bar := survivor_screen + Vector2(-28, -42)
		draw_rect(Rect2(survivor_bar, Vector2(56, 6)), Color("#251f1f"))
		draw_rect(Rect2(survivor_bar, Vector2(56.0 * survivor_health / survivor_max_health, 6)), Color("#63d471"))

	if baseball_spawn >= 0 and not baseball_evacuated:
		var baseball_screen := _map_to_screen(baseball_position)
		if baseball_alive and baseball_zone_move:
			var destination_screen := _map_to_screen(baseball_target)
			var arrow_direction := baseball_screen.direction_to(destination_screen)
			var arrow_tip := destination_screen
			var arrow_base := arrow_tip - arrow_direction * 18.0
			var arrow_side := arrow_direction.orthogonal() * 9.0
			var arrow_color := Color(0.20, 0.65, 1.0, 0.58)
			draw_line(baseball_screen, arrow_base, arrow_color, 4.0)
			draw_colored_polygon(
				PackedVector2Array([arrow_tip, arrow_base + arrow_side, arrow_base - arrow_side]),
				arrow_color
			)
			draw_circle(destination_screen, 11.0, Color(0.20, 0.65, 1.0, 0.22))
			draw_arc(destination_screen, 11.0, 0.0, TAU, 24, arrow_color, 2.0)
		draw_set_transform(baseball_screen, baseball_aim_angle, Vector2(map_zoom, map_zoom))
		var baseball_color := Color.WHITE if baseball_alive else Color(0.35, 0.35, 0.35, 1.0)
		draw_texture_rect(BASEBALL_TEXTURE, Rect2(Vector2(-34, -30), Vector2(68, 60)), false, baseball_color)
		var bat_angle := 0.82
		if baseball_swing_time > 0.0:
			var swing_progress := 1.0 - baseball_swing_time / BASEBALL_SWING_DURATION
			bat_angle = lerpf(-1.15, 1.05, swing_progress)
		var bat_start := Vector2(10, 0).rotated(bat_angle)
		var bat_end := Vector2(52, 0).rotated(bat_angle)
		draw_line(bat_start, bat_end, Color("#b98245"), 8.0)
		draw_circle(bat_end, 5.0, Color("#d1a063"))
		draw_set_transform(Vector2.ZERO, 0.0)
		var baseball_bar := baseball_screen + Vector2(-28, -40)
		draw_rect(Rect2(baseball_bar, Vector2(56, 6)), Color("#251f1f"))
		draw_rect(Rect2(baseball_bar, Vector2(56.0 * baseball_health / baseball_max_health, 6)), Color("#63d471"))

	for zombie in zombies:
		var zombie_position := _map_to_screen(_zombie_position(zombie))
		draw_set_transform(zombie_position, zombie.aim_angle, Vector2(map_zoom, map_zoom))
		draw_texture_rect(ZOMBIE_TEXTURE, Rect2(Vector2(-26, -32), Vector2(52, 64)), false)
		draw_set_transform(Vector2.ZERO, 0.0)
		var bar_position := zombie_position + Vector2(-22, -39)
		draw_rect(Rect2(bar_position, Vector2(44, 6)), Color("#251f1f"))
		draw_rect(Rect2(bar_position, Vector2(44.0 * zombie.hp / ZOMBIE_MAX_HEALTH, 6)), Color("#d85a55"))

	for shot in shots:
		draw_line(_map_to_screen(shot.start), _map_to_screen(shot.end), Color("#ffe184"), 3)
		draw_circle(_map_to_screen(shot.end), 4, Color("#fff4b0"))

	for particle in blood_particles:
		var alpha := clampf(particle.life / BLOOD_PARTICLE_LIFE, 0.0, 1.0)
		draw_circle(_map_to_screen(particle.position), maxf(1.5, 3.5 * map_zoom), Color(0.55, 0.02, 0.02, alpha))

	for effect in level_up_effects:
		var unit_position: Vector2 = survivor_position if effect.unit == "cop" else baseball_position
		var progress: float = 1.0 - float(effect.life) / LEVEL_UP_EFFECT_LIFE
		var popup_position := _map_to_screen(unit_position) + Vector2(-55, -52 - progress * 28.0)
		var alpha := clampf(effect.life / (LEVEL_UP_EFFECT_LIFE * 0.55), 0.0, 1.0)
		var popup_color := Color(1.0, 0.82, 0.22, alpha)
		draw_string(
			ThemeDB.fallback_font,
			popup_position,
			"LEVEL UP!",
			HORIZONTAL_ALIGNMENT_CENTER,
			110,
			20,
			popup_color
		)
		draw_arc(_map_to_screen(unit_position), (28.0 + progress * 18.0) * map_zoom, 0.0, TAU, 32, Color(1.0, 0.78, 0.18, alpha * 0.6), 3.0)

	if survivor_spawn < 0:
		var card := _survivor_card_rect()
		var card_color := Color("#6f8e70") if survivor_selected else Color("#344d38")
		draw_rect(card, card_color)
		draw_rect(card, Color("#9fba9e"), false, 2)
		draw_texture_rect(SURVIVOR_TEXTURE, Rect2(card.position + Vector2(23, 5), Vector2(58, 49)), false)
		draw_string(ThemeDB.fallback_font, card.position + Vector2(10, 78), "COP • 5m", HORIZONTAL_ALIGNMENT_CENTER, 84, 13, Color.WHITE)

	if baseball_spawn < 0:
		var card := _baseball_card_rect()
		var card_color := Color("#7188a4") if baseball_selected else Color("#35465a")
		draw_rect(card, card_color)
		draw_rect(card, Color("#9fb9d2"), false, 2)
		draw_texture_rect(BASEBALL_TEXTURE, Rect2(card.position + Vector2(23, 5), Vector2(58, 49)), false)
		draw_string(ThemeDB.fallback_font, card.position + Vector2(7, 78), "BATTER • ZONE", HORIZONTAL_ALIGNMENT_CENTER, 90, 13, Color.WHITE)

	if dragging_survivor:
		var drag_texture: Texture2D = SURVIVOR_TEXTURE if dragging_unit == "cop" else BASEBALL_TEXTURE
		draw_texture_rect(drag_texture, Rect2(drag_position - Vector2(38, 32), Vector2(76, 64)), false, Color(1, 1, 1, 0.75))

	if survivor_selected and survivor_spawn >= 0 and not survivor_evacuated:
		_draw_survivor_info_panel()
	elif baseball_selected and baseball_spawn >= 0 and not baseball_evacuated:
		_draw_baseball_info_panel()

func _zone_screen_polygon(zone: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		_map_to_screen(zone.position),
		_map_to_screen(Vector2(zone.end.x, zone.position.y)),
		_map_to_screen(zone.end),
		_map_to_screen(Vector2(zone.position.x, zone.end.y))
	])

func _draw_map_preview() -> void:
	var preview_width := minf(440.0, size.x - 40.0)
	var preview_height := minf(240.0, size.y * 0.30)
	var preview := Rect2(
		Vector2((size.x - preview_width) * 0.5, size.y * 0.39),
		Vector2(preview_width, preview_height)
	)
	draw_rect(preview, Color("#2ebd72"))
	draw_rect(preview, Color("#93b49b"), false, 3.0)
	var road_width := preview_height * 0.22
	var junction_x := preview.position.x + preview.size.x * 0.48
	var upper_y := preview.position.y + preview.size.y * 0.32
	var lower_y := preview.position.y + preview.size.y * 0.70
	var road_color := Color("#4b4b4b")
	draw_rect(Rect2(preview.position.x, upper_y - road_width * 0.5, junction_x - preview.position.x, road_width), road_color)
	draw_rect(Rect2(junction_x - road_width * 0.5, preview.position.y, road_width, preview.size.y), road_color)
	draw_rect(Rect2(junction_x, lower_y - road_width * 0.5, preview.end.x - junction_x, road_width), road_color)
	# Small roofless house marker in the northeast lot.
	var house := Rect2(Vector2(preview.end.x - 112.0, preview.position.y + 14.0), Vector2(88.0, 58.0))
	draw_rect(house, Color("#ef6c16"))
	draw_rect(house.grow(-6.0), Color("#c98c4a"))
	draw_line(Vector2(house.position.x + 42.0, house.position.y + 6.0), Vector2(house.position.x + 42.0, house.end.y - 6.0), Color("#454545"), 4.0)
	var column_edges := [0.0, 0.278, 0.667, 1.0]
	var row_edges := [0.0, 0.444, 1.0]
	for row in 2:
		for column in 3:
			var zone_preview := Rect2(
				preview.position + Vector2(preview.size.x * column_edges[column], preview.size.y * row_edges[row]),
				Vector2(
					preview.size.x * (column_edges[column + 1] - column_edges[column]),
					preview.size.y * (row_edges[row + 1] - row_edges[row])
				)
			)
			draw_rect(zone_preview, Color(0.85, 0.73, 0.35, 0.08))
			draw_rect(zone_preview, Color("#d9ba58"), false, 1.5)

func _draw_decor() -> void:
	_draw_house_interior()

	var tree_positions: Array[Vector2] = [
		Vector2(120, 80),
		Vector2(330, 90),
		Vector2(1160, 380),
		Vector2(1210, 170),
		Vector2(125, 680),
		Vector2(285, 790),
		Vector2(1040, 575),
		Vector2(1190, 620),
		Vector2(155, 1180),
		Vector2(1110, 1190)
	]
	for tree_position in tree_positions:
		draw_texture_rect(TREE_TEXTURE, Rect2(tree_position - Vector2(48, 48), Vector2(96, 96)), false)

	draw_texture_rect(MANHOLE_TEXTURE, Rect2(Vector2(260, 360), Vector2(48, 48)), false)
	draw_texture_rect(MANHOLE_TEXTURE, Rect2(Vector2(930, 875), Vector2(48, 48)), false)
	draw_texture_rect(OIL_SPILL_TEXTURE, Rect2(Vector2(465, 425), Vector2(58, 58)), false)
	draw_texture_rect(OIL_SPILL_TEXTURE, Rect2(Vector2(760, 820), Vector2(54, 54)), false)
	for car in _cars():
		var car_center: Vector2 = car.center
		var car_size: Vector2 = car.size
		var car_rotation: float = car.rotation
		draw_set_transform(map_offset + car_center * map_zoom, car_rotation, Vector2(map_zoom, map_zoom))
		draw_texture_rect(CAR_TEXTURE, Rect2(-car_size * 0.5, car_size), false)
	# Restore the map transform for the remaining decor.
	draw_set_transform(map_offset, 0.0, Vector2(map_zoom, map_zoom))
	draw_texture_rect(DEBRIS_TEXTURE, Rect2(Vector2(410, 610), Vector2(64, 64)), false)
	draw_texture_rect(DEBRIS_TEXTURE, Rect2(Vector2(1085, 650), Vector2(56, 56)), false)

func _draw_house_interior() -> void:
	# Roofless top-down house, matching the construction style of Kenney's
	# preview: visible floors, room divisions, furniture and an open entry.
	var house := _house_rect()
	var inside := house.grow(-14.0)
	var kitchen := Rect2(inside.position, Vector2(inside.size.x, 88.0))
	var living := Rect2(inside.position + Vector2(0.0, 88.0), Vector2(inside.size.x, inside.size.y - 88.0))
	draw_rect(Rect2(Vector2(1018, house.end.y), Vector2(58, 82)), Color("#b8c4c2"))
	draw_texture_rect(HOUSE_TILE_FLOOR_TEXTURE, kitchen, true)
	draw_texture_rect(HOUSE_WOOD_FLOOR_TEXTURE, living, true)

	# Orange exterior walls with the dark inner cap used throughout the pack.
	draw_rect(house, Color("#ef6c16"), false, 14.0)
	draw_rect(inside, Color("#454545"), false, 8.0)
	# Interior kitchen wall with a wide doorway.
	draw_line(Vector2(inside.position.x, kitchen.end.y), Vector2(990, kitchen.end.y), Color("#ef6c16"), 12.0)
	draw_line(Vector2(1085, kitchen.end.y), Vector2(inside.end.x, kitchen.end.y), Color("#ef6c16"), 12.0)
	draw_line(Vector2(inside.position.x, kitchen.end.y + 4.0), Vector2(990, kitchen.end.y + 4.0), Color("#454545"), 5.0)
	draw_line(Vector2(1085, kitchen.end.y + 4.0), Vector2(inside.end.x, kitchen.end.y + 4.0), Color("#454545"), 5.0)
	# Open front door in the south wall.
	draw_rect(Rect2(Vector2(1022, house.end.y - 18.0), Vector2(50, 22)), Color("#b57b42"))

	# Kenney furnishings make each room read clearly from above.
	draw_texture_rect(HOUSE_FRIDGE_TEXTURE, Rect2(Vector2(892, 56), Vector2(58, 58)), false)
	draw_texture_rect(HOUSE_STOVE_TEXTURE, Rect2(Vector2(950, 56), Vector2(64, 64)), false)
	draw_texture_rect(HOUSE_CRATE_TEXTURE, Rect2(Vector2(1123, 62), Vector2(54, 54)), false)
	draw_texture_rect(HOUSE_TABLE_TEXTURE, Rect2(Vector2(935, 188), Vector2(72, 72)), false)
	draw_texture_rect(HOUSE_SOFA_TEXTURE, Rect2(Vector2(1080, 198), Vector2(92, 58)), false)
	draw_texture_rect(HOUSE_PLANT_TEXTURE, Rect2(Vector2(1114, 137), Vector2(58, 58)), false)

func _survivor_info_close_rect() -> Rect2:
	return Rect2(Vector2(234, size.y - 168), Vector2(36, 36))

func _draw_survivor_info_close_button(color: Color) -> void:
	var hit_rect := _survivor_info_close_rect()
	var button_rect := hit_rect.grow(-5.0)
	draw_rect(button_rect, Color(0.08, 0.09, 0.10, 0.95))
	draw_rect(button_rect, color, false, 2.0)
	draw_line(button_rect.position + Vector2(7, 7), button_rect.end - Vector2(7, 7), color, 2.5)
	draw_line(Vector2(button_rect.end.x - 7, button_rect.position.y + 7), Vector2(button_rect.position.x + 7, button_rect.end.y - 7), color, 2.5)

func _draw_survivor_info_panel() -> void:
	var panel_size := Vector2(260, 158)
	var panel_position := Vector2(14, size.y - panel_size.y - 14)
	var panel := Rect2(panel_position, panel_size)
	draw_rect(panel, Color(0.035, 0.055, 0.08, 0.92))
	draw_rect(panel, Color(0.25, 0.62, 0.92, 0.9), false, 2.0)
	_draw_survivor_info_close_button(Color("#83c7ff"))

	var portrait := Rect2(panel_position + Vector2(12, 36), Vector2(76, 76))
	draw_rect(portrait, Color(0.10, 0.20, 0.30, 1.0))
	draw_texture_rect(SURVIVOR_TEXTURE, portrait, false)

	draw_string(
		ThemeDB.fallback_font,
		panel_position + Vector2(12, 25),
		"OFFICER REED",
		HORIZONTAL_ALIGNMENT_LEFT,
		220,
		20,
		Color.WHITE
	)
	var status := "RELOADING" if is_reloading else "%d / %d" % [ammo, MAGAZINE_SIZE]
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 52), "POLICE • ACCURACY %d%%" % int(COP_ACCURACY * 100.0), HORIZONTAL_ALIGNMENT_LEFT, 145, 14, Color("#83c7ff"))
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 74), "LEVEL   %d  XP %d/%d" % [cop_level, cop_xp, cop_xp_to_next], HORIZONTAL_ALIGNMENT_LEFT, 150, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 96), "HEALTH  %d / %d" % [survivor_health, survivor_max_health], HORIZONTAL_ALIGNMENT_LEFT, 145, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 118), "AMMO    %s" % status, HORIZONTAL_ALIGNMENT_LEFT, 145, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 140), "KILLS   %d" % cop_kills, HORIZONTAL_ALIGNMENT_LEFT, 145, 15, Color.WHITE)

func _draw_baseball_info_panel() -> void:
	var panel_size := Vector2(260, 158)
	var panel_position := Vector2(14, size.y - panel_size.y - 14)
	var panel := Rect2(panel_position, panel_size)
	draw_rect(panel, Color(0.05, 0.045, 0.035, 0.92))
	draw_rect(panel, Color(0.82, 0.55, 0.27, 0.9), false, 2.0)
	_draw_survivor_info_close_button(Color("#f0b96f"))
	var portrait := Rect2(panel_position + Vector2(12, 36), Vector2(76, 76))
	draw_rect(portrait, Color(0.18, 0.13, 0.08, 1.0))
	draw_texture_rect(BASEBALL_TEXTURE, portrait, false)
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(12, 25), "CASEY MORGAN", HORIZONTAL_ALIGNMENT_LEFT, 220, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 52), "BASEBALL PLAYER", HORIZONTAL_ALIGNMENT_LEFT, 145, 14, Color("#f0b96f"))
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 74), "LEVEL   %d  XP %d/%d" % [baseball_level, baseball_xp, baseball_xp_to_next], HORIZONTAL_ALIGNMENT_LEFT, 150, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 96), "HEALTH  %d / %d" % [baseball_health, baseball_max_health], HORIZONTAL_ALIGNMENT_LEFT, 145, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 118), "BAT DMG %.2f" % _baseball_damage(), HORIZONTAL_ALIGNMENT_LEFT, 145, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 140), "KILLS   %d" % baseball_kills, HORIZONTAL_ALIGNMENT_LEFT, 145, 15, Color.WHITE)
