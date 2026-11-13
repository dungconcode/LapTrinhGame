extends Node

var id:String

func _ready():
	Data.listen(self, "shield.strength")
	Data.listen(self, "shield.additionalstrength")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"shield.additionalstrength":
			finishIfEnough(newValue + Data.of("shield.strength"))
		"shield.strength":
			finishIfEnough(newValue + Data.of("shield.additionalstrength"))

func finishIfEnough(newValue):
	if newValue >= 200:
		Achievements.triggerIfOpen(id)
		Data.unlisten(self, "shield.strength")
		Data.unlisten(self, "shield.additionalstrength")
		queue_free()
