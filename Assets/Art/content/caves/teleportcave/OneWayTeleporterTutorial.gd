extends Tutorial

func _ready():
	super._ready()
	splitTutorialText("level.tutorial.onewayteleporter2", "Label1", "Label2")
	triggered = true

func process_confirm(delta:float):
	if tutorialParent.keeperPlacedEye:
		confirm()
