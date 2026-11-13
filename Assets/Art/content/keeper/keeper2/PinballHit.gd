extends AnimatedSprite2D

func _ready():
	play("hit")


func _on_animation_looped() -> void:
	_PinballHitAnimationFinishedCheck()

func _on_PinballHit_animation_finished() -> void:
	_PinballHitAnimationFinishedCheck()

func _PinballHitAnimationFinishedCheck() -> void:
	queue_free()


