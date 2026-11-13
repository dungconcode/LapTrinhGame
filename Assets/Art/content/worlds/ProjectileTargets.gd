extends Node2D

var center := Vector2() 
var fromPos:Vector2
var positions := []

func _ready():
	for i in get_children():
		center += i.global_position
		positions.append(i.global_position)
	center /= get_child_count()

func getRandom(fromPos:Vector2) -> Vector2:
	self.fromPos = fromPos
	positions.sort_custom(Callable(self, "sortNearest"))
	return positions[randi() % positions.size()/2]

func sortNearest(a:Vector2, b:Vector2):
	return (fromPos - a).length() < (fromPos - b).length()
