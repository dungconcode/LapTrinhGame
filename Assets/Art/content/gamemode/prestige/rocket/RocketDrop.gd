extends Node2D

var target
var offsetY

func _process(delta):
	if target:
		var d = (target.position + Vector2(0,offsetY)) - position 
		position += d * delta * pow(d.length(),2) * randf_range(0.8, 1.2)
