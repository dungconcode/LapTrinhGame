extends Node

var id:String

func _ready():
	Data.listen(self, "game.over")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"game.over":
			if newValue == "won":
				if GameWorld.runTime <= 20 * 60.0:
					Achievements.triggerIfOpen(id)
					Data.unlisten(self, "game.over")
					queue_free()
