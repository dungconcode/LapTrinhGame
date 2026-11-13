extends Node2D

@export var speed := -3.0
@export var repeat_at := -1300.0

func _process(delta):
	position.x += speed*delta
	if position.x < -1300.0:
		position.x += 1300.0
