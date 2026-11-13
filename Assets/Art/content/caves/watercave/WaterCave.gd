extends "res://content/caves/Cave.gd"

func onRevealed():
	find_child("Amb").play()

func serialize()->Dictionary:
	var data = super.serialize()
	for water in [%Water1, %Water2, %Water3]:
		data[water.name + "_taken"] = water.taken
		data[water.name + "_regrowCooldown"] = water.regrowCooldown
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	if currentState == State.REVEALED:
		find_child("Amb").play()
	
	for water in [%Water1, %Water2, %Water3]:
		water.taken = data[water.name + "_taken"]
		water.regrowCooldown = data[water.name + "_regrowCooldown"]
		water.visible = not water.taken
