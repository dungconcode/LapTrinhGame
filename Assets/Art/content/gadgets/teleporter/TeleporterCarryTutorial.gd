extends Tutorial

func _ready():
	super._ready()
	splitTutorialText("level.tutorial.teleporter.carry2", "Label1", "Label2")
	splitTutorialText("level.tutorial.teleporter.carry3", "Label3", "Label4")

func process_trigger(delta:float) -> bool:
	if not tutorialParent.isCarried() and keeper.global_position.distance_to(tutorialParent.global_position) < 72:
		return true
	return false

func process_confirm(delta:float):
	if tutorialParent.isCarried():
		confirm()
