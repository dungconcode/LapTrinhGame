extends Node

var id:String

func _process(delta):
	if get_parent().move.length() >= 200:
		Achievements.triggerIfOpen(id)
		queue_free()
