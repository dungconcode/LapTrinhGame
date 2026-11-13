extends Node

var id:String

func _process(delta):
	if get_parent().liftedRigids.size() >= 80:
		Achievements.triggerIfOpen(id)
		queue_free()
