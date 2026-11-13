extends Node2D

@export var speed := 25.0
@export var left_to_right := true

func _physics_process(delta):
	position.x += speed * delta
	if left_to_right:
		if position.x >= 800:
			position.x = -350.0
	else:
		if position.x <= -350:
			position.x = 800.0
