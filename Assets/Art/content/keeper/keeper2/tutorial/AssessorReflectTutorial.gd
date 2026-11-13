extends Tutorial

func _ready():
	super._ready()
	splitTutorialText("level.tutorial.assessor.reflect.desc1", "LabelDesc1", "LabelDesc2")

func process_trigger(delta:float) -> bool:
	return get_tree().get_nodes_in_group("keeper_projectiles").size() > 0

func process_confirm(delta:float):
	if tutorialParent.ballActionCooldown > 0.0:
		confirm()
