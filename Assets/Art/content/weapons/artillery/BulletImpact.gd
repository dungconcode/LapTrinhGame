extends AnimatedSprite2D

func _ready():
	Style.init(self)
	frame = 0
	rotation += randf_range(-0.1, 0.1)
	scale = Vector2.ONE*randf_range(0.6, 0.8)
	flip_v = false if randi()%2 == 0 else true

func _on_BulletImpact_animation_finished():
	queue_free()
