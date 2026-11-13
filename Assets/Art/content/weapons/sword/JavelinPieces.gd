extends Node2D

func _ready():
	Style.init(self)
	$AnimatedSprite2D.stop()
	hide()

func start(pos, rot):
	global_position = pos
	global_rotation = rot + PI/2
	show()
	$AnimatedSprite2D.play("disintegrate")
	$HitSound.play()
	
func _on_AnimatedSprite_animation_finished():
	queue_free()
