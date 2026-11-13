extends Tutorial

func _ready():
	super._ready()
	splitTutorialText("level.tutorial.assessor.bundle.desc1", "LabelDesc1", "LabelDesc2")

func process_trigger(delta:float) -> bool:
	return tutorialParent.carryables.size() >= 4

func process_confirm(delta:float):
	if get_tree().get_nodes_in_group("bundle").size() > 0:
		confirm()
