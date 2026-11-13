extends Node

var id:String

func _process(delta):
	if get_parent().hatched and Keepers.oneInsideDome():
		Achievements.triggerIfOpen(id)
		queue_free()
