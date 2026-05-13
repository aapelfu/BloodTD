extends Node2D

# --- Configuration ---
@export_group("Scenes")
@export var enemy_scene: PackedScene
@export var tower_scene: PackedScene
@export var tower2_scene: PackedScene
@export var floating_text_scene: PackedScene = preload("res://scenes/FloatingText.tscn")

@export_group("Wave Settings")
@export var total_waves: int = 15
@export var base_enemies_per_wave: int = 5
@export var wave_delay: float = 3.0

@export_group("Game Settings")
@export var base_max_health: int = 10
@export var starting_blood: int = 300
@export var tower_costs: Array[int] = [100, 150]
@export var tower_radius: float = 40.0
@export var path_width: float = 30.0

# --- References ---
@onready var health_bar: AnimatedSprite2D = $HUD/AnimatedSprite2D
@onready var blood_label: Label = $HUD/HBoxContainer/Label
@onready var wave_label: Label = $HUD/"Label de Oleadas"
@onready var start_menu: Control = $UI_Menus/StartMenu
@onready var pause_menu: Control = $UI_Menus/PauseMenu
@onready var game_over_menu: Control = $UI_Menus/GameOverMenu
@onready var camera: Camera2D = $Camera2D

# --- State ---
var path_points: PackedVector2Array
var base_health: int
var blood: int
var game_started: bool = false
var game_over: bool = false

var current_wave: int = 0
var enemies_to_spawn: int = 0
var enemies_alive: int = 0
var wave_in_progress: bool = false

var selected_tower: int = -1
var can_place: bool = false
var preview_node: Node2D

var shake_intensity: float = 0.0
var shake_decay: float = 5.0

func _ready() -> void:
	_init_game()
	_setup_path()
	_setup_audio()
	_setup_preview()
	_update_ui()

func _init_game() -> void:
	get_tree().paused = true
	base_health = base_max_health
	blood = starting_blood
	start_menu.visible = true
	pause_menu.visible = false
	game_over_menu.visible = false

func _setup_path() -> void:
	var path_node: Path2D = $Path2D
	path_points = path_node.curve.get_baked_points()
	for i in path_points.size():
		path_points[i] = path_node.to_global(path_points[i])
	_draw_path_visual()

func _setup_audio() -> void:
	var audio_manager := Node.new()
	audio_manager.set_script(preload("res://scripts/AudioManager.gd"))
	audio_manager.name = "AudioManager"
	add_child(audio_manager)

func _setup_preview() -> void:
	preview_node = Node2D.new()
	preview_node.z_index = 50
	preview_node.draw.connect(_on_preview_draw)
	add_child(preview_node)

func _draw_path_visual() -> void:
	var line := Line2D.new()
	line.width = path_width * 2
	line.default_color = Color(0.25, 0.05, 0.05, 0.4)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	for p in path_points:
		line.add_point(p)
	add_child(line)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel") and game_started and not game_over:
		_toggle_pause()
		
	_handle_camera_shake(delta)
	
	if preview_node:
		preview_node.queue_redraw()

func _handle_camera_shake(delta: float) -> void:
	if shake_intensity > 0:
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta)
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity
	else:
		camera.offset = Vector2.ZERO

func _on_preview_draw() -> void:
	if selected_tower == -1 or not can_place or game_over or not game_started:
		return
		
	var mouse_pos: Vector2 = get_global_mouse_position()
	var is_valid: bool = is_valid_tower_position(mouse_pos)
	var color: Color = Color(0.2, 0.8, 0.2, 0.4) if is_valid else Color(0.8, 0.2, 0.2, 0.4)
	
	preview_node.draw_circle(mouse_pos, tower_radius, color)
	preview_node.draw_circle(mouse_pos, tower_radius, Color(color.r, color.g, color.b, 0.8), false, 2.0)
	
	# Draw phantom sprite
	var tex_path: String = "res://assets/sprites/towers/tower_01/Tower 01.png" if selected_tower == 0 else "res://assets/sprites/towers/tower_02/Tower 02.png"
	var tex := load(tex_path) as Texture2D
	if tex:
		var rect := Rect2(mouse_pos - Vector2(32, 64), Vector2(64, 128))
		preview_node.draw_texture_rect_region(tex, rect, Rect2(0, 0, 64, 128), Color(1, 1, 1, 0.5))

# --- Game Logic ---
func _toggle_pause() -> void:
	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused

func _on_start_button_pressed() -> void:
	start_menu.visible = false
	game_started = true
	get_tree().paused = false
	_start_next_wave()

func _on_resume_button_pressed() -> void:
	_toggle_pause()

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _start_next_wave() -> void:
	current_wave += 1
	if current_wave > total_waves:
		_trigger_victory()
		return
		
	wave_in_progress = true
	enemies_to_spawn = base_enemies_per_wave + (current_wave - 1) * 3
	enemies_alive = enemies_to_spawn
	_update_ui()
	_spawn_wave()

func _spawn_wave() -> void:
	for i in enemies_to_spawn:
		if game_over: return
		await get_tree().create_timer(1.0).timeout
		_spawn_enemy()

func _spawn_enemy() -> void:
	var enemy := enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = path_points[0]
	enemy.setup(path_points)

func enemy_died(enemy: Node2D) -> void:
	enemies_alive -= 1
	_add_blood(20)
	_show_blood_gain_text(enemy.global_position)
	
	if enemies_alive <= 0:
		wave_in_progress = false
		await get_tree().create_timer(wave_delay).timeout
		if not game_over:
			_start_next_wave()

func _show_blood_gain_text(pos: Vector2) -> void:
	var ft = floating_text_scene.instantiate()
	ft.text = "+20🩸"
	ft.color = Color(1, 0.3, 0.3)
	ft.global_position = pos
	add_child(ft)

func _on_enemy_reached_base() -> void:
	_damage_base(1)
	apply_camera_shake(15.0)

func _damage_base(amount: int) -> void:
	base_health = max(0, base_health - amount)
	_update_ui()
	if base_health <= 0 and not game_over:
		_trigger_game_over()

func _add_blood(amount: int) -> void:
	blood += amount
	_update_ui()

func apply_camera_shake(intensity: float) -> void:
	shake_intensity = max(shake_intensity, intensity)

func _trigger_game_over() -> void:
	game_over = true
	get_tree().paused = true
	game_over_menu.visible = true

func _trigger_victory() -> void:
	game_over = true
	print("VICTORIA!") # Could add a victory menu here

# --- Tower Placement ---
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_tower()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			selected_tower = -1

func _try_place_tower() -> void:
	if selected_tower == -1 or not can_place:
		return
		
	var click_pos := get_global_mouse_position()
	if not is_valid_tower_position(click_pos):
		return
		
	var cost := tower_costs[selected_tower]
	if blood >= cost:
		var scene := tower_scene if selected_tower == 0 else tower2_scene
		var tower := scene.instantiate()
		tower.add_to_group("towers")
		add_child(tower)
		tower.global_position = click_pos
		blood -= cost
		selected_tower = -1
		_update_ui()
		apply_camera_shake(5.0)

func is_valid_tower_position(pos: Vector2) -> bool:
	# Check path distance
	for i in range(path_points.size() - 1):
		var p1 := path_points[i]
		var p2 := path_points[i+1]
		var closest := Geometry2D.get_closest_point_to_segment(pos, p1, p2)
		if pos.distance_to(closest) < (path_width + tower_radius):
			return false
			
	# Check other towers
	for node in get_tree().get_nodes_in_group("towers"):
		if pos.distance_to(node.global_position) < (tower_radius * 2):
			return false
			
	return true

func _on_torre_01_pressed() -> void:
	_select_tower(0)

func _on_torre_02_pressed() -> void:
	_select_tower(1)

func _select_tower(index: int) -> void:
	selected_tower = index
	can_place = false
	await get_tree().create_timer(0.1).timeout
	can_place = true

# --- UI Updates ---
func _update_ui() -> void:
	health_bar.frame = clamp(base_health, 0, 10)
	blood_label.text = str(blood) + " 🩸"
	wave_label.text = "Oleada %d/%d" % [current_wave, total_waves]
