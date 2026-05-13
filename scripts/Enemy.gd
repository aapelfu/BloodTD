extends Area2D

var health = 3
var speed = 200.0
var path_points: PackedVector2Array
var current_point = 0

@onready var anim = $AnimatedSprite2D
var floating_text_scene = preload("res://scenes/FloatingText.tscn")

var max_health = 0
var health_bar_bg: ColorRect
var health_bar_fill: ColorRect

func _ready():
	anim.play("walk")
	add_to_group("enemies")
	max_health = health
	
	# Crear barra de vida dinámicamente
	health_bar_bg = ColorRect.new()
	health_bar_bg.color = Color(0.2, 0.0, 0.0, 0.8)
	health_bar_bg.size = Vector2(40, 6)
	health_bar_bg.position = Vector2(-20, -40)
	add_child(health_bar_bg)
	
	health_bar_fill = ColorRect.new()
	health_bar_fill.color = Color(1.0, 0.2, 0.2, 1.0)
	health_bar_fill.size = Vector2(40, 6)
	health_bar_fill.position = Vector2(-20, -40)
	add_child(health_bar_fill)


func setup(points: PackedVector2Array):
	path_points = points

func _process(delta):
	if path_points.is_empty() or current_point >= path_points.size():
		if not path_points.is_empty():
			get_parent()._on_enemy_reached_base()
		queue_free()
		return

	var target = path_points[current_point]
	var direction = (target - global_position).normalized()
	global_position += direction * speed * delta
	anim.set_flip_h(direction.x < 0)

	if global_position.distance_to(target) < 5.0:
		current_point += 1

func take_damage(amount):
	health -= amount
	show_floating_text("-" + str(amount), Color.RED)
	
	if max_health > 0:
		var health_percent = float(health) / float(max_health)
		health_bar_fill.size.x = 40.0 * max(0.0, health_percent)
		
	if health <= 0:
		get_parent().enemy_died()
		queue_free()

func show_floating_text(text, color):
	var ft = floating_text_scene.instantiate()
	ft.text = text
	ft.color = color
	ft.global_position = global_position
	get_parent().add_child(ft)
