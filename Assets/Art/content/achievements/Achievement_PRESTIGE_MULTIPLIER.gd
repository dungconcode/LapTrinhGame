extends Node

var id:String

func _ready():
	Data.listen(self, "prestige.multiplier")

func propertyChanged(property:String, oldValue, newValue):
	if SaveGame.currentLoadingSavegame:
		return
	
	match property:
		# ONLY LOWERCASE HERE
		"prestige.multiplier":
			if newValue >= 10:
				Achievements.triggerIfOpen(id)
				Data.unlisten(self, "prestige.multiplier")
				queue_free()
