extends Node

var id:String
var wavePresentTime:float = -2000
var enterDomeTime:float = -1000

func _ready():
	Data.listen(self, "event.keepers.insidedome")
	Data.listen(self, "monsters.wavepresent")

func propertyChanged(property:String, oldValue, newValue):
	if SaveGame.currentLoadingSavegame:
		return
	
	match property:
		# ONLY LOWERCASE HERE
		"monsters.wavepresent":
			if newValue:
				wavePresentTime = GameWorld.runTime
				triggerIfClose()
		"event.keepers.insidedome":
			if newValue:
				if GameWorld.runTime - enterDomeTime < 20.0:
					# don't triger if dome was recently entered
					enterDomeTime = GameWorld.runTime
				else:
					enterDomeTime = GameWorld.runTime
					triggerIfClose()

func triggerIfClose():
	if abs(wavePresentTime - enterDomeTime) <= 1.0:
		Achievements.triggerIfOpen(id)
		Data.unlisten(self, "monsters.wavepresent")
		Data.unlisten(self, "event.keepers.insidedome")
		queue_free()
