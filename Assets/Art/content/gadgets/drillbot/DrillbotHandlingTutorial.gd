extends Tutorial

var wasDropped := false

func _ready():
	super._ready()
	splitTutorialText("level.tutorial.drillbot.handling1", "Label1", "Label2")
	splitTutorialText("level.tutorial.drillbot.handling2", "Label3", "Label4")

func process_trigger(delta:float) -> bool:
	if tutorialParent.isWorking() and keeper.global_position.distance_to(tutorialParent.global_position) < 72:
		return true
	return false

func process_confirm(delta:float):
	if not tutorialParent.isCarried():
		wasDropped = true
	
	if wasDropped and tutorialParent.isCarried():
		confirm()

