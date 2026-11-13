extends "res://content/caves/Cave.gd"

func onRevealed():
	find_child("Amb").play()

func serialize()->Dictionary:
	var data = super.serialize()
	data["cobalt1"] = find_child("Cobalt1") != null
	data["cobalt2"] = find_child("Cobalt2") != null
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	if currentState == State.REVEALED:
		find_child("Amb").play()
	
	if not data["cobalt1"]:
		find_child("Cobalt1").queue_free()
	if not data["cobalt2"]:
		find_child("Cobalt2").queue_free()
