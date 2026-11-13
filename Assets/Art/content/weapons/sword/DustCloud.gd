extends Node2D


func _ready():
	$AnimatedSprite2D.play("burst")


func flip():
	$AnimatedSprite2D.flip_h = true


func _on_AnimatedSprite_animation_finished():
	queue_free()
