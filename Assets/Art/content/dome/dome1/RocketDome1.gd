extends Node2D


func start():
	$Sprite2D.play("start")

func _on_sprite_2d_animation_looped() -> void:
	_AnimatedSpriteAnimationFinishedCheck()

func _on_AnimatedSprite_animation_finished() -> void:
	_AnimatedSpriteAnimationFinishedCheck()

func _AnimatedSpriteAnimationFinishedCheck() -> void:
	if $Sprite2D.animation == "start":
		$Sprite2D.play("launch")
	elif $Sprite2D.animation == "launch":
		$Sprite2D.play("fly")
		$Tween.interpolate_property(self, "position:y", position.y, position.y - 500, 3.0, Tween.TRANS_QUAD, Tween.EASE_IN)
		$Tween.start()


