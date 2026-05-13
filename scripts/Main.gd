extends Node2D

# Escenas
@export var enemy_scene: PackedScene
@export var tower_scene: PackedScene

# Referencias
@onready var health_bar = $HUD/AnimatedSprite2D
@onready var blood_label = $HUD/HBoxContainer/Label
@onready var ui_menus = $UI_Menus
@onready var start_menu = $UI_Menus/StartMenu
@onready var pause_menu = $UI_Menus/PauseMenu
@onready var game_over_menu = $UI_Menus/GameOverMenu
@onready var camera = $Camera2D

var floating_text_scene = preload("res://scenes/FloatingText.tscn")
var preview_node: Node2D

# Camera Shake
var shake_intensity = 0.0
var shake_decay = 5.0

# Estado base
var path_points: PackedVector2Array
var base_health = 10
var blood = 300
var game_started = false
var game_over = false

# Torres
@export var tower2_scene: PackedScene
var tower_costs = [100, 150]
var selected_tower = -1  # -1 = ninguna seleccionada
var preview_tower = null
var tower_radius = 40.0
var path_width = 30.0

# Oleadas
var current_wave = 0
var total_waves = 15
var enemies_per_wave = 5
var enemies_alive = 0
var wave_in_progress = false

func _ready():
	# Configuración inicial de UI
	get_tree().paused = true
	start_menu.visible = true
	pause_menu.visible = false
	game_over_menu.visible = false
	
	# Instanciar Audio Manager
	var audio_manager = Node.new()
	audio_manager.set_script(preload("res://scripts/AudioManager.gd"))
	audio_manager.name = "AudioManager"
	add_child(audio_manager)
	
	# Nodo para dibujar previsualización encima de todo
	preview_node = Node2D.new()
	preview_node.z_index = 50
	preview_node.draw.connect(_on_preview_draw)
	add_child(preview_node)
	
	# Calcular puntos del camino
	var path = $Path2D
	path_points = path.curve.get_baked_points()
	for i in path_points.size():
		path_points[i] = $Path2D.to_global(path_points[i])
		
	draw_path_visual()
	update_health_bar()
	update_hud()

func draw_path_visual():
	var line = Line2D.new()
	line.width = path_width * 2
	line.default_color = Color(0.2, 0.0, 0.0, 0.4) # Color tierra/sangre semitransparente profesional
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.z_index = 0
	
	for p in path_points:
		line.add_point(p)
	add_child(line)

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel") and game_started and not game_over:
		toggle_pause()
		
	# Camera shake logic
	if shake_intensity > 0:
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta)
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity
	else:
		camera.offset = Vector2.ZERO
		
	if preview_node:
		preview_node.queue_redraw()

func _on_preview_draw():
	if selected_tower != -1 and can_place and not game_over and game_started:
		var mouse_pos = get_global_mouse_position()
		var is_valid = is_valid_tower_position(mouse_pos)
		var color = Color(0, 1, 0, 0.3) if is_valid else Color(1, 0, 0, 0.3)
		preview_node.draw_circle(mouse_pos, tower_radius, color)
		preview_node.draw_circle(mouse_pos, tower_radius, Color(color.r, color.g, color.b, 0.8), false, 3.0)
		
		# Dibujar el sprite fantasma de la torre
		var tex = null
		if selected_tower == 0:
			tex = load("res://assets/sprites/towers/tower_01/Tower 01.png")
		else:
			tex = load("res://assets/sprites/towers/tower_02/Tower 02.png")
			
		if tex:
			var rect = Rect2(mouse_pos - Vector2(32, 64), Vector2(64, 128)) # Tamaño aprox
			preview_node.draw_texture_rect_region(tex, rect, Rect2(0,0,64,128), Color(1,1,1,0.5))

func toggle_pause():
	if get_tree().paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	get_tree().paused = true
	pause_menu.visible = true

func resume_game():
	get_tree().paused = false
	pause_menu.visible = false

func _on_start_button_pressed():
	start_menu.visible = false
	game_started = true
	get_tree().paused = false
	start_wave()

func _on_resume_button_pressed():
	resume_game()

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

# --- ENEMIGOS ---
func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = path_points[0]
	enemy.setup(path_points)

func _on_base_area_entered(area):
	if area.is_in_group("enemies"):
		_damage_base()
		area.queue_free()

func _on_enemy_reached_base():
	_damage_base()
	apply_camera_shake(15.0)

func apply_camera_shake(intensity: float):
	shake_intensity = max(shake_intensity, intensity)

func _damage_base():
	base_health -= 1
	update_health_bar()
	if base_health <= 0 and not game_over:
		trigger_game_over()

func trigger_game_over():
	game_over = true
	get_tree().paused = true
	game_over_menu.visible = true

func add_blood(amount):
	blood += amount
	update_hud()

func enemy_died():
	enemies_alive -= 1
	add_blood(20)
	
	# Buscar al último enemigo (muy crudo, pero funciona para la demo visual)
	for child in get_children():
		if child.is_in_group("enemies") and child.health <= 0:
			var ft = floating_text_scene.instantiate()
			ft.text = "+20🩸"
			ft.color = Color(1, 0.2, 0.2)
			ft.global_position = child.global_position
			add_child(ft)
			
	if enemies_alive <= 0:
		wave_in_progress = false
		await get_tree().create_timer(3.0).timeout
		start_wave()

# --- OLEADAS ---
func start_wave():
	current_wave += 1
	if current_wave > total_waves:
		print("¡VICTORIA!")
		return
	wave_in_progress = true
	enemies_alive = enemies_per_wave + (current_wave - 1) * 3
	update_hud()
	spawn_wave()

func spawn_wave():
	for i in enemies_alive:
		await get_tree().create_timer(1.0).timeout
		spawn_enemy()

# --- TORRES ---
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if selected_tower == -1 or not can_place:
				return
			
			var click_pos = get_global_mouse_position()
			if not is_valid_tower_position(click_pos):
				print("No puedes construir ahí")
				return
				
			var cost = tower_costs[selected_tower]
			if blood >= cost:
				var scene = tower_scene if selected_tower == 0 else tower2_scene
				var tower = scene.instantiate()
				tower.add_to_group("towers")
				add_child(tower)
				tower.global_position = click_pos
				blood -= cost
				selected_tower = -1
				update_hud()
				apply_camera_shake(5.0)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			selected_tower = -1

func is_valid_tower_position(pos: Vector2) -> bool:
	for i in range(path_points.size() - 1):
		var p1 = path_points[i]
		var p2 = path_points[i+1]
		var closest = Geometry2D.get_closest_point_to_segment(pos, p1, p2)
		if pos.distance_to(closest) < (path_width + tower_radius):
			return false
			
	for node in get_tree().get_nodes_in_group("towers"):
		if pos.distance_to(node.global_position) < (tower_radius * 2):
			return false
			
	return true

var can_place = false

func _on_torre_01_pressed():
	select_tower(0)

func _on_torre_02_pressed():
	select_tower(1)

func select_tower(index):
	selected_tower = index
	can_place = false
	await get_tree().create_timer(0.1).timeout
	can_place = true

# --- HUD ---
func update_health_bar():
	health_bar.frame = clamp(base_health, 0, 10)

func update_hud():
	blood_label.text = str(blood) + " 🩸"
	$HUD/"Label de Oleadas".text = "Oleada " + str(current_wave) + "/15"
