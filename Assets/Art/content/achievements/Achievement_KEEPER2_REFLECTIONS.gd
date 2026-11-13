extends Node

var id:String

func _process(delta):
	if get_parent().consecutiveReflections >= 40:
		Achievements.triggerIfOpen(id)
		queue_free()
