extends Node

var id:String

func _ready():
	Data.listen(self, "event.keepers.insidedome")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"event.keepers.insidedome":
			for keeper in Keepers.getAll():
				if keeper.isInsideDome and keeper.techId == "keeper1" and keeper.carriedCarryables.size() >= 20:
					Achievements.triggerIfOpen(id)
					Data.unlisten(self, "event.keepers.insidedome")
					queue_free()
