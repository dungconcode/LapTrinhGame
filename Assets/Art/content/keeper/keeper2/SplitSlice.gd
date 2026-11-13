extends AnimatedSprite2D

func _ready():
	play("slice")


func _on_animation_looped() -> void:
	_SplitSliceAnimationFinishedCheck()

func _on_SplitSlice_animation_finished() -> void:
	_SplitSliceAnimationFinishedCheck()

func _SplitSliceAnimationFinishedCheck() -> void:
	queue_free()


