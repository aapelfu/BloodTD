extends CharacterBody2D

const SPEED = 200.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		anim.play("run")
		anim.flip_h = direction.x < 0
	else:
		velocity = Vector2.ZERO
		anim.play("idle")
	
	move_and_slide()
