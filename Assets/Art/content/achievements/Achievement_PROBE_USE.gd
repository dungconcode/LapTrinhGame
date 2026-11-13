extends Node

var id:String

var markers := []

func _process(delta):
	for m in get_tree().get_nodes_in_group("probe_markers"):
		if not markers.has(m.tileCoord):
			markers.append(m.tileCoord)
	if markers.size() >= 15:
		Achievements.triggerIfOpen(id)
		Data.unlisten(self, "monsters.cycle")
		queue_free()

func _ready():
	Data.listen(self, "monsters.cycle")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"monsters.cycle":
			if newValue:
				markers.clear()
