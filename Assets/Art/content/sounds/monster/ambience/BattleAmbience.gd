extends Node

var ambiences := []
var canRun := true

func _ready():
	Data.listen(self, "monsters.wavepresent")
	Data.listen(self, "game.over")
	for c in get_children():
		if c is AudioStreamPlayer:
			ambiences.append(c)

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"monsters.wavepresent":
			if newValue:
				canRun = true
				for c in ambiences:
					c.roundStarts()
			else:
				canRun = false
				for c in ambiences:
					c.update(0)
		"game.over":
			if newValue == "won" or newValue == "lost":
				canRun = false
				for c in ambiences:
					c.update(0)

func _process(delta):
	if not canRun and not GameWorld.forceBattleAmbienceEnabled:
		return
	
	var monsters = get_tree().get_nodes_in_group("monster")
	var countByType := {}
	for m in monsters:
		countByType[m.techId] = countByType.get(m.techId, 0) + 1
	
	for c in ambiences:
		var type = c.name.substr(0, c.name.find("_")).to_lower()
		c.update(countByType.get(type, 0))
