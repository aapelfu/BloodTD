extends Area2D

var health = 3
var speed = 200.0
var path_points: PackedVector2Array
var current_point = 0

@onready var anim = $AnimatedSprite2D

func _ready():
	anim.play("walk")
	add_to_group("enemies")

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
	if health <= 0:
		get_parent().enemy_died()
		queue_free()
