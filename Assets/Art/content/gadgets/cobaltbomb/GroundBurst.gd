extends Node2D

func _ready():
	$AnimatedSprite2D.play("burst")
	Style.init(self)

func _on_AnimatedSprite_animation_finished():
	queue_free()
