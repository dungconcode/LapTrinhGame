extends Node

var id:String

func _ready():
	Data.listen(self, "monsters.cycle")

func propertyChanged(property:String, oldValue, newValue):
	if SaveGame.currentLoadingSavegame:
		return
	
	match property:
		# ONLY LOWERCASE HERE
		"monsters.cycle":
			var fraction:float = Data.of("dome.health") / float(Data.of("dome.maxHealth"))
			if fraction <= 0.01:
				Achievements.triggerIfOpen(id)
				Data.unlisten(self, "monsters.cycle")
				queue_free()
