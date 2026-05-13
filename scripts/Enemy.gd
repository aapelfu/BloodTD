extends Area2D

@export var health: int = 3
@export var speed: float = 200.0

var path_points: PackedVector2Array
var current_point: int = 0
var max_health: int = 0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var floating_text_scene: PackedScene = preload("res://scenes/FloatingText.tscn")

var health_bar_bg: ColorRect
var health_bar_fill: ColorRect

func _ready() -> void:
	anim.play("walk")
	add_to_group("enemies")
	max_health = health
	_setup_health_bar()

func _setup_health_bar() -> void:
	health_bar_bg = ColorRect.new()
	health_bar_bg.color = Color(0.1, 0.1, 0.1, 0.7)
	health_bar_bg.size = Vector2(40, 4)
	health_bar_bg.position = Vector2(-20, -35)
	add_child(health_bar_bg)
	
	health_bar_fill = ColorRect.new()
	health_bar_fill.color = Color(0.8, 0.1, 0.1, 0.9)
	health_bar_fill.size = Vector2(40, 4)
	health_bar_fill.position = Vector2(-20, -35)
	add_child(health_bar_fill)

func setup(points: PackedVector2Array) -> void:
	path_points = points

func _process(delta: float) -> void:
	if path_points.is_empty() or current_point >= path_points.size():
		if not path_points.is_empty():
			var main = get_tree().current_scene # Assuming Main is current scene
			if main.has_method("_on_enemy_reached_base"):
				main._on_enemy_reached_base()
		queue_free()
		return

	var target: Vector2 = path_points[current_point]
	var direction: Vector2 = (target - global_position).normalized()
	global_position += direction * speed * delta
	anim.flip_h = direction.x < 0

	if global_position.distance_to(target) < 5.0:
		current_point += 1

func take_damage(amount: int) -> void:
	health -= amount
	show_floating_text("-" + str(amount), Color.RED)
	
	if max_health > 0:
		var health_percent: float = float(health) / float(max_health)
		health_bar_fill.size.x = 40.0 * clamp(health_percent, 0.0, 1.0)
		
	if health <= 0:
		var main = get_tree().current_scene
		if main.has_method("enemy_died"):
			main.enemy_died(self)
		queue_free()

func show_floating_text(text: String, color: Color) -> void:
	var ft = floating_text_scene.instantiate()
	ft.text = text
	ft.color = color
	ft.global_position = global_position
	get_parent().add_child(ft)
