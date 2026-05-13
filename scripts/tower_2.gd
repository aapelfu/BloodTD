extends Area2D

@export var damage: int = 2
@export var projectile_scene: PackedScene

@onready var weapon: AnimatedSprite2D = $weapon
@onready var timer: Timer = $Timer

var target: Area2D = null

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)

func _process(_delta: float) -> void:
	_update_target()
	if is_instance_valid(target):
		weapon.rotation = global_position.direction_to(target.global_position).angle()

func _update_target() -> void:
	var enemies: Array[Area2D] = get_overlapping_areas()
	target = null
	var min_dist: float = INF
	
	for e in enemies:
		if e.is_in_group("enemies"):
			var dist: float = global_position.distance_to(e.global_position)
			if dist < min_dist:
				min_dist = dist
				target = e

func _on_timer_timeout() -> void:
	if is_instance_valid(target):
		_shoot()

func _shoot() -> void:
	weapon.play("weapon")
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.setup(target, damage)
	
	# Retroceso animation
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.05)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
