extends Control

const ZOMBIE_TEXTURE := preload("res://assets/kenney/zombie.png")
const SURVIVOR_TEXTURE := preload("res://assets/kenney/survivor.png")
const BASEBALL_TEXTURE := preload("res://assets/kenney/baseball.png")
const GRASS_TEXTURE := preload("res://assets/kenney/grass.png")
const ROAD_TEXTURE := preload("res://assets/kenney/road.png")
const SIDEWALK_TEXTURE := preload("res://assets/kenney/sidewalk.png")
const STARTING_HEALTH := 10
const TILE_SIZE := 64.0
const MAP_SIZE_TILES := 20
const MAP_OVERSCAN := TILE_SIZE * 24.0
const CAMERA_NODE_EDGE_RATIO := 0.18
const CAMERA_SPRING_SPEED := 11.0
const OVERSCROLL_RESISTANCE := 0.32
const ZOMBIE_SPEED := 0.069
const ZOMBIE_CHASE_SPEED := 55.0
const ZOMBIE_ATTACK_RANGE := 34.0
const ZOMBIE_ATTACK_RATE := 0.8
const ZOMBIE_COLLISION_DIAMETER := 44.0
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
const BASEBALL_KNOCKBACK_SPEED := 420.0
const ZOMBIE_KNOCKBACK_DECELERATION := 1225.0
const BASEBALL_AOE_METERS := 0.9
const BASEBALL_SWING_DURATION := 0.28
const ZOMBIE_MAX_HEALTH := 3
const FIRE_RATE := 0.65
const MAGAZINE_SIZE := 10
const RELOAD_TIME := 1.8
const EARLY_RELOAD_AT := 5
const BLOOD_PARTICLE_LIFE := 0.45
const LEVEL_UP_EFFECT_LIFE := 1.25
const SURVIVOR_SPEED := 120.0
const SURVIVOR_COMBAT_SPEED := 40.0
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
	version_label = _make_label(16, Color("#c4d0c1"))
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
	if DisplayServer.get_name() == "headless":
		call_deferred("_run_headless_gameplay_smoke_test")

func _run_headless_gameplay_smoke_test() -> void:
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

	if not map_dragging and active_touches.size() < 2:
		var resting_offset := _clamped_map_offset(map_offset)
		map_offset = map_offset.lerp(resting_offset, 1.0 - exp(-CAMERA_SPRING_SPEED * delta))

	_update_wave(delta)
	_update_zombies(delta)
	if screen != "playing":
		return
	_update_survivor(delta)
	_update_baseball_survivor(delta)

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
		"x": randf_range(-0.14, -0.08),
		"y": spawn_y,
		"path_offset": spawn_y - _road_center().y,
		"turned": false,
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
			zombie.x = knocked_position.x / _map_size().x
			zombie.y = knocked_position.y
			zombie.knockback_velocity = knockback_velocity.move_toward(
				Vector2.ZERO,
				ZOMBIE_KNOCKBACK_DECELERATION * delta
			)
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
				var direction := zombie_position.direction_to(swarm_position)
				var speed: float = ZOMBIE_CHASE_SPEED * zombie.speed_multiplier * zombie.movement_factor
				zombie.x += direction.x * speed * delta / _map_size().x
				zombie.y += direction.y * speed * delta
			else:
				zombie.attack_cooldown -= delta
				if zombie.attack_cooldown <= 0.0:
					_damage_survivor_target(target_id)
					zombie.attack_cooldown = ZOMBIE_ATTACK_RATE
		else:
			var zombie_position := _zombie_position(zombie)
			var path_offset := float(zombie.path_offset)
			var corner := _road_turn() + Vector2(-path_offset, path_offset)
			if not bool(zombie.turned) and zombie_position.distance_to(corner) <= 8.0:
				zombie.turned = true
			var route_target := Vector2(
				_road_turn().x - path_offset,
				_map_size().y + MAP_OVERSCAN
			) if bool(zombie.turned) else corner
			var route_direction := zombie_position.direction_to(route_target)
			var desired_angle := zombie_position.angle_to_point(route_target)
			zombie.aim_angle = rotate_toward(zombie.aim_angle, desired_angle, ZOMBIE_TURN_SPEED * delta)
			var route_speed: float = ZOMBIE_SPEED * _map_size().x * zombie.speed_multiplier * zombie.movement_factor
			zombie.x += route_direction.x * route_speed * delta / _map_size().x
			zombie.y += route_direction.y * route_speed * delta

		if bool(zombie.turned) and zombie.y > _map_size().y * 1.08:
			zombies.erase(zombie)
			zombies_passed += 1
			health -= 1
			if health <= 0:
				_show_results()
				return

	_separate_zombies()

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

func _survivor_target_alive(target_id: String) -> bool:
	if target_id == "cop":
		return survivor_spawn >= 0 and survivor_alive
	if target_id == "baseball":
		return baseball_spawn >= 0 and baseball_alive
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
	for zombie in zombies:
		if zombie.target_id == "baseball":
			zombie.target_id = ""

func _update_survivor(delta: float) -> void:
	if survivor_spawn < 0 or not survivor_alive:
		return

	if is_reloading:
		reload_time_remaining -= delta
		if reload_time_remaining <= 0.0:
			is_reloading = false
			ammo = MAGAZINE_SIZE
		else:
			return

	survivor_target = _spawn_points()[survivor_spawn]
	var target := _closest_zombie()
	var distance_to_zombie := INF
	if not target.is_empty():
		distance_to_zombie = survivor_position.distance_to(_zombie_position(target))

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
			survivor_position = survivor_position.move_toward(
				survivor_target,
				SURVIVOR_COMBAT_SPEED * delta
			)
	elif distance_to_destination > 1.0:
		survivor_is_walking = true
		survivor_position = survivor_position.move_toward(survivor_target, SURVIVOR_SPEED * delta)
	else:
		survivor_is_walking = false

func _update_baseball_survivor(delta: float) -> void:
	if baseball_spawn < 0 or not baseball_alive:
		return

	baseball_target = _spawn_points()[baseball_spawn]
	baseball_attack_cooldown -= delta
	baseball_swing_time = maxf(0.0, baseball_swing_time - delta)
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
				var max_roam := BASEBALL_ROAM_METERS * TILE_SIZE
				if next_position.distance_to(baseball_target) <= max_roam:
					baseball_position = next_position
			else:
				baseball_is_walking = false
		elif distance <= BASEBALL_MELEE_METERS * TILE_SIZE:
			baseball_is_walking = false
			_swing_bat(target)
		else:
			baseball_is_walking = true
			baseball_position = baseball_position.move_toward(target_position, BASEBALL_SPEED * delta)
	else:
		var distance_home := baseball_position.distance_to(baseball_target)
		if distance_home > 1.0:
			baseball_is_walking = true
			var home_angle := baseball_position.angle_to_point(baseball_target)
			baseball_aim_angle = rotate_toward(baseball_aim_angle, home_angle, SURVIVOR_TURN_SPEED * delta)
			baseball_position = baseball_position.move_toward(baseball_target, BASEBALL_SPEED * delta)
		else:
			baseball_is_walking = false

func _closest_zombie_in_baseball_roam() -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance := INF
	for zombie in zombies:
		var zombie_position := _zombie_position(zombie)
		if zombie_position.distance_to(baseball_target) > BASEBALL_ROAM_METERS * TILE_SIZE:
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
		zombie.hp -= BASEBALL_DAMAGE
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
	var target_position := _zombie_position(target)
	shots.append({"start":survivor_position, "end":target_position, "life":0.12})
	ammo -= 1
	for i in 7:
		var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		blood_particles.append({
			"position": target_position + direction * randf_range(2.0, 8.0),
			"velocity": direction * randf_range(20.0, 65.0),
			"life": BLOOD_PARTICLE_LIFE * randf_range(0.65, 1.0)
		})
	# The zombie that was hit acquires the shooter if it was still wandering.
	if String(target.target_id) == "":
		target.target_id = "cop"

	# Other untargeted zombies may hear the shot. Hearing is local and
	# intentionally unreliable, keeping the whole swarm from turning at once.
	var hearing_range := GUNSHOT_HEARING_RANGE_METERS * TILE_SIZE
	for zombie in zombies:
		if zombie == target or String(zombie.target_id) != "":
			continue
		if _zombie_position(zombie).distance_to(survivor_position) <= hearing_range:
			if randf() <= GUNSHOT_RETARGET_CHANCE:
				zombie.target_id = "cop"

	var knockback_direction := survivor_position.direction_to(target_position)
	var knocked_position := target_position + knockback_direction * ZOMBIE_HIT_KNOCKBACK
	target.x = knocked_position.x / _map_size().x
	target.y = knocked_position.y
	target.movement_factor = 0.08
	fire_cooldown = FIRE_RATE
	target.hp -= 1
	if target.hp <= 0:
		zombies.erase(target)
		zombies_killed += 1
		cop_kills += 1
		_award_cop_xp()

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
	shots.clear()
	blood_particles.clear()
	level_up_effects.clear()
	map_zoom = 1.0
	map_offset = _centered_map_offset()
	map_dragging = false
	active_touches.clear()
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
				map_dragging = not _handle_pointer_down(event.position)
				map_drag_position = event.position
			elif active_touches.size() == 2:
				map_dragging = false
				dragging_survivor = false
				dragging_unit = ""
				pinch_distance = _touch_distance()
		else:
			if active_touches.size() == 1 and dragging_survivor:
				_handle_pointer_up(event.position)
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
	var touched_cop := (
		(survivor_spawn < 0 and _survivor_card_rect().has_point(position))
		or (survivor_spawn >= 0 and survivor_alive and _map_to_screen(survivor_position).distance_to(position) <= 42.0)
	)
	var touched_baseball := (
		(baseball_spawn < 0 and _baseball_card_rect().has_point(position))
		or (baseball_spawn >= 0 and baseball_alive and _map_to_screen(baseball_position).distance_to(position) <= 42.0)
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
	elif survivor_selected or baseball_selected:
		var index := _spawn_point_at(position)
		if index >= 0:
			_set_selected_survivor_destination(index)
			return true
		# Empty map space clears selection and then behaves like a normal map drag.
		survivor_selected = false
		baseball_selected = false
		dragging_unit = ""
		queue_redraw()
	return false

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
		else:
			survivor_spawn = index
			survivor_target = _spawn_points()[index]
			survivor_is_walking = survivor_position.distance_to(survivor_target) > 1.0
			survivor_selected = false
	elif baseball_selected:
		if baseball_spawn < 0:
			_place_baseball_survivor(index)
		else:
			baseball_spawn = index
			baseball_target = _spawn_points()[index]
			baseball_selected = false
	dragging_survivor = false
	dragging_unit = ""
	queue_redraw()

func _place_survivor(index: int) -> void:
	survivor_spawn = index
	survivor_target = _spawn_points()[index]
	survivor_position = _survivor_entry_position()
	survivor_aim_angle = -PI * 0.5
	survivor_is_walking = true
	survivor_selected = false
	dragging_survivor = false
	fire_cooldown = 0.0

func _place_baseball_survivor(index: int) -> void:
	baseball_spawn = index
	baseball_target = _spawn_points()[index]
	baseball_position = _survivor_entry_position()
	baseball_aim_angle = -PI * 0.5
	baseball_is_walking = true
	baseball_selected = false
	dragging_survivor = false
	baseball_attack_cooldown = 0.0

func _spawn_point_at(position: Vector2) -> int:
	position = _screen_to_map(position)
	var points := _spawn_points()
	for i in points.size():
		var occupied_by_other := (
			(i == survivor_spawn and baseball_selected)
			or (i == baseball_spawn and survivor_selected)
		)
		if not occupied_by_other and points[i].distance_to(position) <= 38.0:
			return i
	return -1

func _map_size() -> Vector2:
	var side := MAP_SIZE_TILES * TILE_SIZE
	return Vector2(side, side)

func _field_rect() -> Rect2:
	return Rect2(Vector2.ZERO, _map_size())

func _road_center() -> Vector2:
	# Keep the bend aligned to whole tiles so sidewalk pieces meet cleanly.
	return Vector2(TILE_SIZE * 14.0, TILE_SIZE * 8.0)

func _road_turn() -> Vector2:
	return _road_center()

func _road_rect() -> Rect2:
	var half_width := STREET_WIDTH_TILES * TILE_SIZE * 0.5
	var turn := _road_turn()
	return Rect2(
		-MAP_OVERSCAN,
		turn.y - half_width,
		turn.x + half_width + MAP_OVERSCAN,
		half_width * 2.0
	)

func _vertical_road_rect() -> Rect2:
	var half_width := STREET_WIDTH_TILES * TILE_SIZE * 0.5
	var turn := _road_turn()
	return Rect2(
		turn.x - half_width,
		turn.y - half_width,
		half_width * 2.0,
		_map_size().y - turn.y + half_width + MAP_OVERSCAN
	)

func _sidewalk_rects() -> Array[Rect2]:
	var horizontal := _road_rect()
	var vertical := _vertical_road_rect()
	var sidewalk_width := SIDEWALK_WIDTH_TILES * TILE_SIZE
	var turn := _road_turn()
	var half_width := STREET_WIDTH_TILES * TILE_SIZE * 0.5
	return [
		Rect2(horizontal.position.x, horizontal.position.y - sidewalk_width, horizontal.size.x, sidewalk_width),
		Rect2(horizontal.position.x, horizontal.end.y, turn.x - half_width - horizontal.position.x, sidewalk_width),
		Rect2(vertical.position.x - sidewalk_width, turn.y + half_width, sidewalk_width, vertical.end.y - turn.y - half_width),
		Rect2(vertical.end.x, vertical.position.y, sidewalk_width, vertical.size.y),
		# Fill the outside elbow where the top and right sidewalks meet.
		Rect2(vertical.end.x, horizontal.position.y - sidewalk_width, sidewalk_width, sidewalk_width)
	]

func _survivor_entry_position() -> Vector2:
	return Vector2(_road_turn().x, _map_size().y + 55.0)

func _spawn_points() -> Array[Vector2]:
	var turn := _road_turn()
	var half_width := STREET_WIDTH_TILES * TILE_SIZE * 0.5
	return [
		Vector2(_map_size().x * 0.27, turn.y - half_width - TILE_SIZE * 0.38),
		Vector2(_map_size().x * 0.49, turn.y + half_width + TILE_SIZE * 0.32),
		Vector2(turn.x - half_width - TILE_SIZE * 0.34, _map_size().y * 0.64),
		Vector2(turn.x + half_width + TILE_SIZE * 0.36, _map_size().y * 0.79)
	]

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
	if screen != "playing":
		return

	var map_size := _map_size()
	var terrain_extent := Rect2(
		Vector2(-MAP_OVERSCAN, -MAP_OVERSCAN),
		map_size + Vector2.ONE * MAP_OVERSCAN * 2.0
	)
	var road := _road_rect()
	var vertical_road := _vertical_road_rect()

	# Draw in map space so Kenney's 64 px tiles zoom and pan with the world.
	draw_set_transform(map_offset, 0.0, Vector2(map_zoom, map_zoom))
	draw_texture_rect(GRASS_TEXTURE, terrain_extent, true)
	# Draw three non-overlapping pieces so the two stretched textures do not
	# create a visible seam through the middle of the turn.
	var approach_road := Rect2(
		road.position,
		Vector2(vertical_road.position.x - road.position.x, road.size.y)
	)
	var corner_road := Rect2(vertical_road.position, Vector2(vertical_road.size.x, road.size.y))
	var exit_road := Rect2(
		Vector2(vertical_road.position.x, road.end.y),
		Vector2(vertical_road.size.x, vertical_road.end.y - road.end.y)
	)
	var asphalt_color := Color("#4b4b4b")
	draw_rect(approach_road, asphalt_color)
	draw_rect(corner_road, asphalt_color)
	draw_rect(exit_road, asphalt_color)
	for sidewalk in _sidewalk_rects():
		draw_texture_rect(SIDEWALK_TEXTURE, sidewalk, true)
	draw_set_transform(Vector2.ZERO, 0.0)

	# The road and sidewalks extend through the overscan past both soft bounds,
	# so dragging beyond an edge still looks like the street continues.

	var points := _spawn_points()
	for i in points.size():
		var point := _map_to_screen(points[i])
		var occupied := i == survivor_spawn or i == baseball_spawn
		var choosing := survivor_selected or baseball_selected
		var point_color := Color("#d9ba58") if choosing and not occupied else Color("#78917a")
		draw_circle(point, 30 * map_zoom, Color(point_color, 0.35))
		draw_arc(point, 30 * map_zoom, 0, TAU, 32, point_color, 3)
		if not occupied:
			draw_string(ThemeDB.fallback_font, point + Vector2(-7, 7), "+", HORIZONTAL_ALIGNMENT_CENTER, 14, 22, point_color)

	if survivor_spawn >= 0:
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
		if survivor_alive:
			draw_circle(survivor_screen, _survivor_range() * map_zoom, Color(0.45, 0.72, 0.48, 0.08))
			draw_arc(survivor_screen, _survivor_range() * map_zoom, 0, TAU, 48, Color(0.45, 0.72, 0.48, 0.25), 2)
		draw_set_transform(survivor_screen, survivor_aim_angle, Vector2(map_zoom, map_zoom))
		var survivor_color := Color.WHITE if survivor_alive else Color(0.35, 0.35, 0.35, 1.0)
		draw_texture_rect(SURVIVOR_TEXTURE, Rect2(Vector2(-38, -32), Vector2(76, 64)), false, survivor_color)
		draw_set_transform(Vector2.ZERO, 0.0)
		var survivor_bar := survivor_screen + Vector2(-28, -42)
		draw_rect(Rect2(survivor_bar, Vector2(56, 6)), Color("#251f1f"))
		draw_rect(Rect2(survivor_bar, Vector2(56.0 * survivor_health / survivor_max_health, 6)), Color("#63d471"))

	if baseball_spawn >= 0:
		var baseball_screen := _map_to_screen(baseball_position)
		if baseball_alive and baseball_selected:
			var home_screen := _map_to_screen(baseball_target)
			draw_circle(home_screen, BASEBALL_ROAM_METERS * TILE_SIZE * map_zoom, Color(0.25, 0.55, 1.0, 0.06))
			draw_arc(home_screen, BASEBALL_ROAM_METERS * TILE_SIZE * map_zoom, 0, TAU, 64, Color(0.25, 0.55, 1.0, 0.22), 2)
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
		draw_string(ThemeDB.fallback_font, card.position + Vector2(7, 78), "BATTER • 7m", HORIZONTAL_ALIGNMENT_CENTER, 90, 13, Color.WHITE)

	if dragging_survivor:
		var drag_texture: Texture2D = SURVIVOR_TEXTURE if dragging_unit == "cop" else BASEBALL_TEXTURE
		draw_texture_rect(drag_texture, Rect2(drag_position - Vector2(38, 32), Vector2(76, 64)), false, Color(1, 1, 1, 0.75))

	if survivor_selected and survivor_spawn >= 0:
		_draw_survivor_info_panel()
	elif baseball_selected and baseball_spawn >= 0:
		_draw_baseball_info_panel()

func _draw_survivor_info_panel() -> void:
	var panel_size := Vector2(260, 158)
	var panel_position := Vector2(14, size.y - panel_size.y - 14)
	var panel := Rect2(panel_position, panel_size)
	draw_rect(panel, Color(0.035, 0.055, 0.08, 0.92))
	draw_rect(panel, Color(0.25, 0.62, 0.92, 0.9), false, 2.0)

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
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 52), "POLICE OFFICER", HORIZONTAL_ALIGNMENT_LEFT, 145, 14, Color("#83c7ff"))
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
	var portrait := Rect2(panel_position + Vector2(12, 36), Vector2(76, 76))
	draw_rect(portrait, Color(0.18, 0.13, 0.08, 1.0))
	draw_texture_rect(BASEBALL_TEXTURE, portrait, false)
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(12, 25), "CASEY MORGAN", HORIZONTAL_ALIGNMENT_LEFT, 220, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 52), "BASEBALL PLAYER", HORIZONTAL_ALIGNMENT_LEFT, 145, 14, Color("#f0b96f"))
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 74), "LEVEL   %d  XP %d/%d" % [baseball_level, baseball_xp, baseball_xp_to_next], HORIZONTAL_ALIGNMENT_LEFT, 150, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 96), "HEALTH  %d / %d" % [baseball_health, baseball_max_health], HORIZONTAL_ALIGNMENT_LEFT, 145, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 118), "WEAPON  BAT", HORIZONTAL_ALIGNMENT_LEFT, 145, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, panel_position + Vector2(100, 140), "KILLS   %d" % baseball_kills, HORIZONTAL_ALIGNMENT_LEFT, 145, 15, Color.WHITE)
