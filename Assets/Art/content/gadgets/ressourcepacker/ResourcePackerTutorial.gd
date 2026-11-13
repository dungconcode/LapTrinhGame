extends Tutorial

var pickedUp := false

func _ready() -> void:
	super._ready()
	
	splitTutorialText("level.tutorial.resourcepacker.popup_1", "Label1", "Label2")

func process_confirm(delta:float):
	for drop in get_tree().get_nodes_in_group("drops"):
		if drop.type == "pack":
			confirm()

func process_trigger(delta:float) -> bool:
	return keeper.focussedCarryable and keeper.focussedCarryable.carryableType == "resource"
