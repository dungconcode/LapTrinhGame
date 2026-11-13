extends "res://content/caves/Cave.gd"

func onRevealed():
	find_child("Amb").play()

func serialize()->Dictionary:
	var data = super.serialize()
	for iron in [%Iron1, %Iron2, %Iron3, %Iron4, %Iron5]:
		data[iron.name + "_taken"] = iron.taken
		data[iron.name + "_regrowCooldown"] = iron.regrowCooldown
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	if currentState == State.REVEALED:
		find_child("Amb").play()
	
	for iron in [%Iron1, %Iron2, %Iron3, %Iron4, %Iron5]:
		iron.taken = data[iron.name + "_taken"]
		iron.regrowCooldown = data[iron.name + "_regrowCooldown"]
		iron.visible = not iron.taken
