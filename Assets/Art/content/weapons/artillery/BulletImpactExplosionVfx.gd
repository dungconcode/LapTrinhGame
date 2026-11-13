extends AnimatedSprite2D

func _ready():
	Style.init(self)
	frame = 0
	rotation += randf_range(-0.1, 0.1)
	scale = Vector2.ONE*randf_range(0.3, 0.5)
	flip_v = false if randi()%2 == 0 else true
	$Smoke.restart()


func _on_Timer_timeout():
	queue_free()
