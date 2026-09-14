extends Control

const MAP_COUNT := 10
const CAMPAIGN_ZOMBIES := 10000
const BASE_WAVE := 18
const MAX_VISIBLE_ZOMBIES := 80

var survivors := [
	{"name":"Mara","hp":100.0,"max_hp":100.0,"damage":14.0,"rate":0.72,"level":1,"xp":0,"kills":0,"alive":true,"cooldown":0.0,"color":Color("#4fc3f7")},
	{"name":"Jonah","hp":125.0,"max_hp":125.0,"damage":10.0,"rate":0.52,"level":1,"xp":0,"kills":0,"alive":true,"cooldown":0.0,"color":Color("#ffca58")},
	{"name":"Iris","hp":80.0,"max_hp":80.0,"damage":20.0,"rate":1.05,"level":1,"xp":0,"kills":0,"alive":true,"cooldown":0.0,"color":Color("#e782ff")}
]
var zombies: Array[Dictionary] = []
var map_number := 1
var wave_remaining := BASE_WAVE
var carried_threat := 0
var town_hp := 100
var run_kills := 0
var total_spawned := 0
var spawn_timer := 0.25
var rally_time := 0.0
var rally_cooldown := 0.0
var state := "playing"
var message := "Hold the line."
var message_time := 3.0
var retreat_button: Button
var rally_button: Button
var restart_button: Button
var title_label: Label
var stats_label: Label
var version_label: Label
var message_label: Label
var survivor_labels: Array[Label] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	set_process(true)
	set_process_input(true)
	_build_ui()
	_layout_ui()
	queue_redraw()

func _build_ui() -> void:
	title_label = _label(28, Color.WHITE)
	title_label.text = "LAST LINE"
	title_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)

	stats_label = _label(16, Color("#d9e5d6"))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	version_label = _label(12, Color("#91a18e"))
	version_label.text = "%s • %s" % [BuildVersion.BRANCH, BuildVersion.COMMIT]
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	message_label = _label(18, Color("#fff2b2"))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	for survivor in survivors:
		var label := _label(14, Color.WHITE)
		survivor_labels.append(label)

	retreat_button = _button("TACTICAL RETREAT", Color("#b94b45"))
	retreat_button.pressed.connect(_retreat)
	rally_button = _button("RALLY", Color("#477d52"))
	rally_button.pressed.connect(_rally)
	restart_button = _button("NEW RUN", Color("#52749a"))
	restart_button.pressed.connect(_new_run)
	restart_button.hide()
	_update_ui()

func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _button(text_value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 16)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.12)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	add_child(button)
	return button

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout_ui()
		queue_redraw()

func _layout_ui() -> void:
	var w := size.x
	var h := size.y
	var compact := w < 700.0
	title_label.position = Vector2(18, 10)
	title_label.size = Vector2(250, 40)
	version_label.position = Vector2(w - 230, 8)
	version_label.size = Vector2(215, 25)
	stats_label.position = Vector2(12, 50)
	stats_label.size = Vector2(w - 24, 30)
	message_label.position = Vector2(10, 82)
	message_label.size = Vector2(w - 20, 30)
	var button_y := h - 62
	if compact:
		retreat_button.position = Vector2(12, button_y)
		retreat_button.size = Vector2(w * 0.58 - 18, 50)
		rally_button.position = Vector2(w * 0.58 + 3, button_y)
		rally_button.size = Vector2(w * 0.42 - 15, 50)
	else:
		retreat_button.position = Vector2(w * 0.5 - 220, button_y)
		retreat_button.size = Vector2(240, 50)
		rally_button.position = Vector2(w * 0.5 + 30, button_y)
		rally_button.size = Vector2(190, 50)
	restart_button.position = Vector2(w * 0.5 - 90, h * 0.58)
	restart_button.size = Vector2(180, 54)
	var card_w := minf(190.0, (w - 32.0) / 3.0)
	for i in survivor_labels.size():
		survivor_labels[i].position = Vector2(12 + i * card_w, h - 112)
		survivor_labels[i].size = Vector2(card_w - 6, 44)

func _process(delta: float) -> void:
	if state != "playing":
		queue_redraw()
		return
	rally_time = maxf(0.0, rally_time - delta)
	rally_cooldown = maxf(0.0, rally_cooldown - delta)
	message_time = maxf(0.0, message_time - delta)
	_spawn_zombies(delta)
	_update_zombies(delta)
	_update_survivors(delta)
	_check_state()
	_update_ui()
	queue_redraw()

func _spawn_zombies(delta: float) -> void:
	if wave_remaining <= 0 or zombies.size() >= MAX_VISIBLE_ZOMBIES:
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		var toughness := 1.0 + (map_number - 1) * 0.28
		zombies.append({
			"x":1.04 + rng.randf_range(0.0,0.08),
			"lane":rng.randi_range(0,2),
			"hp":32.0 * toughness,
			"max_hp":32.0 * toughness,
			"speed":rng.randf_range(0.020,0.034) * (1.0 + map_number * 0.025),
			"attack":5.0 + map_number * 1.2,
			"bite":0.0
		})
		wave_remaining -= 1
		total_spawned += 1
		spawn_timer = maxf(0.16, 0.72 - map_number * 0.035)

func _update_zombies(delta: float) -> void:
	for z in zombies.duplicate():
		var defender := _lane_survivor(z.lane)
		var stop_x := 0.28 if defender.is_empty() else 0.34
		if z.x > stop_x:
			z.x -= z.speed * delta
		else:
			if defender.is_empty():
				carried_threat += 1
				town_hp = maxi(0, town_hp - 2)
				zombies.erase(z)
			else:
				z.bite -= delta
				if z.bite <= 0.0:
					defender.hp -= z.attack
					z.bite = 0.85
					if defender.hp <= 0:
						defender.hp = 0
						defender.alive = false
						message = "%s was lost for this run." % defender.name
						message_time = 3.0

func _update_survivors(delta: float) -> void:
	for lane in survivors.size():
		var s: Dictionary = survivors[lane]
		if not s.alive:
			continue
		s.cooldown -= delta
		var target := _closest_zombie(lane)
		if not target.is_empty() and s.cooldown <= 0.0:
			target.hp -= s.damage
			s.cooldown = s.rate * (0.58 if rally_time > 0.0 else 1.0)
			if target.hp <= 0.0:
				zombies.erase(target)
				s.kills += 1
				s.xp += 1
				run_kills += 1
				_try_level(s)

func _try_level(s: Dictionary) -> void:
	var needed: int = s.level * 5
	if s.xp < needed:
		return
	s.xp -= needed
	s.level += 1
	var choice := rng.randi_range(0,2)
	if choice == 0:
		s.damage *= 1.22
		message = "%s Lv.%d: Sharpshooter (+damage)" % [s.name, s.level]
	elif choice == 1:
		s.rate *= 0.84
		message = "%s Lv.%d: Quick Hands (+speed)" % [s.name, s.level]
	else:
		s.max_hp += 22
		s.hp = minf(s.max_hp, s.hp + 22)
		message = "%s Lv.%d: Tough (+health)" % [s.name, s.level]
	message_time = 3.0

func _closest_zombie(lane: int) -> Dictionary:
	var result: Dictionary = {}
	var closest := 2.0
	for z in zombies:
		if z.lane == lane and z.x < closest:
			closest = z.x
			result = z
	return result

func _lane_survivor(lane: int) -> Dictionary:
	var s: Dictionary = survivors[lane]
	return s if s.alive else {}

func _check_state() -> void:
	var living := 0
	for s in survivors:
		if s.alive:
			living += 1
	if living == 0 or town_hp <= 0:
		state = "lost"
		message = "THE LINE FELL — %d zombies stopped" % run_kills
		restart_button.show()
	elif wave_remaining == 0 and zombies.is_empty():
		if map_number >= MAP_COUNT:
			state = "won"
			message = "TOWN SAVED — %d zombies stopped" % run_kills
			restart_button.show()
		else:
			_advance_map(0)

func _retreat() -> void:
	if state != "playing" or map_number >= MAP_COUNT:
		return
	var pursuit := wave_remaining + zombies.size() + carried_threat
	zombies.clear()
	_advance_map(pursuit)
	message = "Retreated. %d zombies followed you." % pursuit
	message_time = 4.0

func _advance_map(pursuit: int) -> void:
	map_number += 1
	carried_threat = 0
	wave_remaining = BASE_WAVE + map_number * 6 + pursuit
	spawn_timer = 0.3
	for s in survivors:
		if s.alive:
			s.hp = s.max_hp
	message = "Map %d — survivors healed. Hold the line." % map_number
	message_time = 3.5

func _rally() -> void:
	if state != "playing" or rally_cooldown > 0.0:
		return
	rally_time = 5.0
	rally_cooldown = 14.0
	message = "RALLY! Fire rate increased."
	message_time = 2.0

func _new_run() -> void:
	get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("retreat"):
		_retreat()
	elif event.is_action_pressed("rally"):
		_rally()
	elif event.is_action_pressed("restart") and state != "playing":
		_new_run()

func _update_ui() -> void:
	stats_label.text = "MAP %d/%d    TOWN %d%%    STOPPED %d    INCOMING %d" % [map_number, MAP_COUNT, town_hp, run_kills, wave_remaining + zombies.size()]
	message_label.text = message if message_time > 0.0 or state != "playing" else ""
	rally_button.text = "RALLY %.0fs" % ceil(rally_cooldown) if rally_cooldown > 0.0 else "RALLY"
	rally_button.disabled = rally_cooldown > 0.0 or state != "playing"
	retreat_button.disabled = state != "playing" or map_number >= MAP_COUNT
	for i in survivors.size():
		var s: Dictionary = survivors[i]
		survivor_labels[i].text = "%s  Lv.%d\n%s" % [s.name, s.level, ("%d/%d HP" % [ceil(s.hp),ceil(s.max_hp)]) if s.alive else "DEAD"]

func _draw() -> void:
	var w := size.x
	var h := size.y
	var top := 116.0
	var bottom := h - 122.0
	var field_h := maxf(150.0, bottom - top)
	draw_rect(Rect2(0,0,w,h), Color("#101810"))
	draw_rect(Rect2(0,top,w,field_h), Color("#263d2d"))
	for lane in 3:
		var y := top + field_h * (lane + 0.5) / 3.0
		draw_line(Vector2(0,y + field_h/6.0),Vector2(w,y + field_h/6.0),Color("#38533d"),2)
		draw_line(Vector2(w*0.29,top),Vector2(w*0.29,bottom),Color("#dfc36b"),4)
		var s: Dictionary = survivors[lane]
		var p := Vector2(w*0.25,y)
		if s.alive:
			draw_circle(p,18,s.color)
			draw_circle(p + Vector2(8,-4),7,Color("#ead1af"))
			draw_line(p + Vector2(14,0),p + Vector2(29,0),Color("#31383c"),5)
			_health_bar(p + Vector2(-25,-31),50,s.hp/s.max_hp,Color("#63d471"))
		else:
			draw_line(p-Vector2(14,14),p+Vector2(14,14),Color("#8b3333"),6)
			draw_line(p+Vector2(-14,14),p+Vector2(14,-14),Color("#8b3333"),6)
	for z in zombies:
		var zy: float = top + field_h * (float(z.lane) + 0.5) / 3.0
		var zp := Vector2(z.x*w,zy)
		draw_circle(zp,17,Color("#79a85b"))
		draw_circle(zp+Vector2(-6,-4),3,Color("#f1efba"))
		draw_circle(zp+Vector2(6,-4),3,Color("#f1efba"))
		draw_line(zp+Vector2(-7,7),zp+Vector2(7,7),Color("#4d302e"),3)
		_health_bar(zp+Vector2(-18,-27),36,z.hp/z.max_hp,Color("#d85a55"))
	if rally_time > 0.0:
		draw_string(ThemeDB.fallback_font,Vector2(w*0.5-45,top+24),"RALLY!",HORIZONTAL_ALIGNMENT_CENTER,90,20,Color("#ffe46b"))
	if state != "playing":
		draw_rect(Rect2(0,top,w,field_h),Color(0,0,0,0.62))

func _health_bar(pos: Vector2, width: float, ratio: float, color: Color) -> void:
	draw_rect(Rect2(pos,Vector2(width,5)),Color("#251f1f"))
	draw_rect(Rect2(pos,Vector2(width*clampf(ratio,0,1),5)),color)
