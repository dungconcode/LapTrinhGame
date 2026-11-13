extends Tutorial

func _ready():
	super._ready()
	splitTutorialText("level.tutorial.teleporter.teleport1", "Label1", "Label2")

func process_trigger(delta:float) -> bool:
	if not tutorialParent.isCarried() and keeper.global_position.distance_to(tutorialParent.global_position) < 48:
		return true
	return false

func process_confirm(delta:float):
	if tutorialParent.isTeleporting():
		confirm()
