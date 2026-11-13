extends Node

var id:String

func _process(delta):
	if GameWorld.travelledDistance * CONST.PixelPerKilometer >= 21.097:
		Achievements.triggerIfOpen(id)
		queue_free()
