extends Tutorial

func _ready():
	super._ready()
	listen("orchard.remainingbuffduration." + keeper.playerId)
	splitTutorialText("level.tutorial.fruit.popup_2", "Label1", "Label2")

func beforeMoveIn():
	find_child("OrchardImage").texture = load("res://content/gadgets/orchard/" + Level.domeId() + "/orchard_tutpic.png")
	find_child("OrchardImage").custom_minimum_size = find_child("OrchardImage").texture.get_size() * 2

func propertyChanged(property:String, oldValue, newValue):
	if newValue > 0.0:
		confirm()

func process_trigger(delta:float) -> bool:
	if Data.of("orchard.currentgrowth") >= 1.0:
		if keeper.isInsideDome and not keeper.isInsideStation:
			return true
		return false
	else:
		return false
