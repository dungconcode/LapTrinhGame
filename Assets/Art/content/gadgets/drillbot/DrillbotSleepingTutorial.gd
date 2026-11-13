extends Tutorial

var readied := false

func _ready():
	super._ready()
	splitTutorialText("level.tutorial.drillbot.sleeping2", "Label1", "Label2")
	splitTutorialText("level.tutorial.drillbot.sleeping3", "Label3", "Label4")
	moveIn()

func process_trigger(delta:float) -> bool:
	if tutorialParent.getRemainingSleepTime() >= 15 and keeper.global_position.distance_to(tutorialParent.global_position) < 72:
		return true
	return false

func process_confirm(delta:float):
	if tutorialParent.getRemainingSleepTime() <= 0:
		confirm()
