extends Tutorial

var type:String
var techId:String

func _ready():
	super._ready()
	splitTutorialText("level.tutorial.overcharge.popup_2", "Label1", "Label2")
	splitTutorialText("level.tutorial.overcharge.popup_3", "Label3", "Label4")
	
	if GameWorld.upgrades.has("orchard"):
		type = "orchard"
		techId = "orchardovercharge"
	elif GameWorld.upgrades.has("repellent"):
		type = "repellent"
		techId = "repellentovercharge"
	elif GameWorld.upgrades.has("droneyard"):
		type = "droneyard"
		techId = "droneyardovercharge1"
	elif GameWorld.upgrades.has("shield"):
		type = "shield"
		techId = "shieldovercharge"
	else:
		Logger.error("Can't add overcharge tutorial without having a primary gadget present.", "OverchargeTutorial._ready")
		type = "unknown"
	
	Data.listen(self, type + ".overcharged")

func propertyChanged(property:String, oldValue, newValue):
	if newValue:
		confirm()
		Data.unlisten(self, type + ".overcharged")

func process_trigger(delta:float) -> bool:
	if GameWorld.boughtUpgrades.has(techId):
		if keeper.isInsideDome and not keeper.isInsideStation:
			return true
	return false
