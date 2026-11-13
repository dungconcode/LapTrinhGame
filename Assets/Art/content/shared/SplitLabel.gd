extends HBoxContainer

@export var loc_id: String

func _ready():
	var text = tr(loc_id)
	var split = text.split("|", false, 2)
	find_child("Label1").text = split[0]
	if split.size() == 2:
		find_child("Label2").text = split[1]
