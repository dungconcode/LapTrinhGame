extends Node

var id:String

func _process(delta):
	if GameWorld.runStats.get("blastcharges_used", 0) >= 15:
		Achievements.triggerIfOpen(id)
		queue_free()
