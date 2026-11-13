extends Node

var id:String

func _ready():
	if not Level.loadout:
		queue_free()
		return
	
	Data.listen(self, "inventory.sand")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"inventory.sand":
			if newValue >= 8:
				Achievements.triggerIfOpen(id)
				Data.unlisten(self, "inventory.sand")
				queue_free()
