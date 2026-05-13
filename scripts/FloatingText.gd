extends Node2D

@onready var label = $Label

var text = ""
var color = Color(1, 1, 1)

func _ready():
	label.text = text
	label.modulate = color
	
	# Animación usando Tween
	var tween = create_tween()
	# Mover hacia arriba
	tween.tween_property(self, "position", position + Vector2(0, -50), 1.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Desvanecer al mismo tiempo
	var tween_alpha = create_tween()
	tween_alpha.tween_property(label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR)
	
	# Borrar el nodo al terminar
	tween.tween_callback(queue_free)
