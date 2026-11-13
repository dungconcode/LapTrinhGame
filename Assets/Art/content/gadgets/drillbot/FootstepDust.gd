extends AnimatedSprite2D

func _ready():
	play("default")


func _on_AnimatedSprite_animation_finished():
	queue_free()
