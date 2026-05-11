extends Node2D

# Escenas
@export var enemy_scene: PackedScene
@export var tower_scene: PackedScene

# Referencias
@onready var health_bar = $HUD/AnimatedSprite2D
@onready var blood_label = $HUD/HBoxContainer/Label

# Estado base
var path_points: PackedVector2Array
var base_health = 10
var blood = 300

# Torres
@export var tower2_scene: PackedScene
var tower_costs = [100, 150]
var selected_tower = -1  # -1 = ninguna seleccionada
var preview_tower = null

# Oleadas
var current_wave = 0
var total_waves = 15
var enemies_per_wave = 5
var enemies_alive = 0
var wave_in_progress = false

func _ready():
	# Calcular puntos del camino
	var path = $Path2D
	path_points = path.curve.get_baked_points()
	for i in path_points.size():
		path_points[i] = $Path2D.to_global(path_points[i])
	
	update_health_bar()
	update_hud()
	start_wave()

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

func _damage_base():
	base_health -= 1
	update_health_bar()
	if base_health <= 0:
		print("GAME OVER")
		get_tree().reload_current_scene()

func add_blood(amount):
	blood += amount
	update_hud()

func enemy_died():
	enemies_alive -= 1
	add_blood(20)
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
			if selected_tower == -1:
				return
			var cost = tower_costs[selected_tower]
			if blood >= cost:
				var scene = tower_scene if selected_tower == 0 else tower2_scene
				var tower = scene.instantiate()
				add_child(tower)
				tower.global_position = get_global_mouse_position()
				blood -= cost
				selected_tower = -1
				update_hud()
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			selected_tower = -1

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
