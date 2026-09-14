extends Control

const ZOMBIE_TEXTURE := preload("res://assets/kenney/zombie.png")
const STARTING_HEALTH := 10
const ZOMBIE_SPEED := 0.16

var screen := "menu"
var health := STARTING_HEALTH
var zombies_passed := 0
var zombie_x := -0.1
var spawn_delay := 0.6
var zombie_active := false

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
	title_label.position = Vector2(10, size.y * 0.18)
	title_label.size = Vector2(size.x - 20, 55)

	version_label.position = Vector2(size.x - 225, 8)
	version_label.size = Vector2(210, 22)

	health_label.position = Vector2(10, 55)
	health_label.size = Vector2(size.x - 20, 40)

	results_label.position = Vector2(10, size.y * 0.38)
	results_label.size = Vector2(size.x - 20, 70)

	begin_button.position = Vector2(center_x - 100, size.y * 0.52)
	begin_button.size = Vector2(200, 58)

	retry_button.position = Vector2(center_x - 155, size.y * 0.58)
	retry_button.size = Vector2(145, 58)

	menu_button.position = Vector2(center_x + 10, size.y * 0.58)
	menu_button.size = Vector2(145, 58)

func _process(delta: float) -> void:
	if screen != "playing":
		return

	if zombie_active:
		zombie_x += ZOMBIE_SPEED * delta
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
			zombie_x = -0.1
			zombie_active = true

	health_label.text = "TOWN HEALTH: %d" % health
	queue_redraw()

func _start_game() -> void:
	screen = "playing"
	health = STARTING_HEALTH
	zombies_passed = 0
	zombie_x = -0.1
	spawn_delay = 0.5
	zombie_active = false
	title_label.hide()
	results_label.hide()
	begin_button.hide()
	retry_button.hide()
	menu_button.hide()
	health_label.show()
	health_label.text = "TOWN HEALTH: %d" % health
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
	results_label.text = "%d zombies got through." % zombies_passed
	results_label.show()
	begin_button.hide()
	retry_button.show()
	menu_button.show()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#111812"))

	if screen == "playing":
		var field_top := 110.0
		var field_bottom := size.y - 45.0
		var field_height := maxf(120.0, field_bottom - field_top)
		draw_rect(Rect2(0, field_top, size.x, field_height), Color("#334a35"))

		var road_height := minf(150.0, field_height * 0.55)
		var road_y := field_top + (field_height - road_height) * 0.5
		draw_rect(Rect2(0, road_y, size.x, road_height), Color("#5b5a50"))
		draw_line(Vector2(0, road_y), Vector2(size.x, road_y), Color("#7b795f"), 4)
		draw_line(Vector2(0, road_y + road_height), Vector2(size.x, road_y + road_height), Color("#7b795f"), 4)

		if zombie_active:
			var zombie_position := Vector2(zombie_x * size.x, road_y + road_height * 0.5)
			draw_texture_rect(
				ZOMBIE_TEXTURE,
				Rect2(zombie_position - Vector2(30, 39), Vector2(60, 78)),
				false
			)
