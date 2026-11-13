extends Sprite2D

func _process(delta):
	if visible:
		rotation = randf_range(-0.15, 0.15)
#		rotation = rand_range(-5 * delta, 5 * delta)
	else:
		rotation = 0
