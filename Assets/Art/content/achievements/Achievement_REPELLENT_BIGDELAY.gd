extends Node

var id:String

func _ready():
	Data.listen(self, "repellent.delayedcycles")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"repellent.delayedcycles":
			if oldValue and newValue:
				var diff = newValue - oldValue
				if diff >= 0.5:
					Achievements.triggerIfOpen(id)
					queue_free()
