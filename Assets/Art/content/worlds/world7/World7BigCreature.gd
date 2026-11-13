extends Node2D

@export var offset := 25.0
@export var left_to_right := true

func advance_position():
	position.x += offset
	if left_to_right:
		if position.x >= 800:
			position.x = -350.0
	else:
		if position.x <= -350:
			position.x = 800.0
