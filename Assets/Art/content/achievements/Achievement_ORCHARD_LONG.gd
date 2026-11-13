extends Node

var id:String

func _ready():
	for keeper in Keepers.getAll():
		Data.listen(self, "orchard.remainingbuffduration." + keeper.playerId)

func propertyChanged(property:String, oldValue, newValue):
	if newValue >= 0.74 * GameWorld.getTimeBetweenWaves():
		Achievements.triggerIfOpen(id)
		for keeper in Keepers.getAll():
			Data.unlisten(self, "orchard.remainingbuffduration." + keeper.playerId)
		queue_free()
