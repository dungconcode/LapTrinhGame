extends Tutorial

func _ready():
	super._ready()
	var key = keeper.playerId + ".probe.chargesRemaining"
	listen(key)
	
	splitTutorialText("level.tutorial.probe.popup_1", "Label1", "Label2")

func propertyChanged(property:String, oldValue, newValue):
	if oldValue and newValue < oldValue:
		confirm()

func process_trigger(delta:float) -> bool:
	return keeper.position.y > 100.0
