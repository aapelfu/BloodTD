extends Area2D

var target = null
var damage = 2
@export var projectile_scene: PackedScene
@onready var weapon = $weapon

func _ready():
	$Timer.timeout.connect(_on_timer_timeout)
	print("Torre 2 lista, timer: ", $Timer)

func _process(delta):
	var enemies = get_overlapping_areas()
	target = null
	var min_dist = INF
	for e in enemies:
		if e.is_in_group("enemies"):
			var dist = global_position.distance_to(e.global_position)
			if dist < min_dist:
				min_dist = dist
				target = e
	if target != null:
		weapon.rotation = global_position.direction_to(target.global_position).angle()
	if enemies.size() > 0:
		print("Enemigos en rango: ", enemies.size())

func _on_timer_timeout():
	print("Timer! Target: ", target)
	if target != null and is_instance_valid(target):
		print("Disparando!")
		weapon.play("shoot")
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position
		projectile.setup(target, damage)
