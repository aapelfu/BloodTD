extends Area2D

var speed = 400
var target = null
var damage = 2

func setup(t, d):
	target = t
	damage = d

func _process(delta):
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta
	rotation = direction.angle()
	
	if global_position.distance_to(target.global_position) < 10:
		target.take_damage(damage)
		queue_free()
