extends Node

var id:String

func _ready():
	Data.listen(self, "prestige.score")

func propertyChanged(property:String, oldValue, newValue):
	if SaveGame.currentLoadingSavegame:
		return
	
	match property:
		# ONLY LOWERCASE HERE
		"prestige.score":
			if newValue - oldValue >= 200:
				Achievements.triggerIfOpen(id)
				Data.unlisten(self, "prestige.score")
				queue_free()
