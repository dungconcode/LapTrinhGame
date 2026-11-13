extends Node

var id:String

func _process(delta):
	if get_parent().carryInfluences.size() >= 25:
		Achievements.triggerIfOpen(id)
		queue_free()
