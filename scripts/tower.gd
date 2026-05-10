extends Area2D

var target = null
var damage = 1
@export var projectile_scene: PackedScene

func _ready():
	$Timer.timeout.connect(_on_timer_timeout)

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

func _on_timer_timeout():
	if target != null and is_instance_valid(target):
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position
		projectile.setup(target, damage)
