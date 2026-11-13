extends Node

var id:String

func _ready():
	Data.listen(self, "inventory.floatingsand")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"inventory.floatingsand":
			if newValue == 1 and oldValue == 0 and Data.of("inventory.sand") == 0:
				var relHealth = Data.of("dome.health") / float(Data.of("dome.maxhealth"))
				if relHealth <= 0.1:
					Achievements.triggerIfOpen(id)
					Data.unlisten(self, "inventory.floatingsand")
					queue_free()
