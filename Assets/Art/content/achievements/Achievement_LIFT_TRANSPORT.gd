extends Node

var id:String

func _process(delta):
	if GameWorld.runStats.get("lift_carried_drops", 0) >= 200:
		Achievements.triggerIfOpen(id)
		queue_free()
