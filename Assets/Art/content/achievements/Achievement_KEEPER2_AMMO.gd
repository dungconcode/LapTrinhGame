extends Node

var id:String

func _ready():
	Data.listen(self, get_parent().playerId + ".keeper2.remainingspheres")

func propertyChanged(property:String, oldValue, newValue):
	if SaveGame.currentLoadingSavegame:
		return
	
	if newValue == 6:
		Achievements.triggerIfOpen(id)
		Data.unlisten(self, get_parent().playerId + "keeper2.remainingspheres")
		queue_free()
