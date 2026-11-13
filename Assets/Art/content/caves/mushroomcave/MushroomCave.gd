extends "res://content/caves/Cave.gd"

var hasMushroom := true
var timeUntilNewMushroom := 0.0
var lastKeeper:String
var speedBuffAmount := 45.0

func serialize()->Dictionary:
	var data = super.serialize()
	data["hasMushroom"] = hasMushroom
	data["timeUntilNewMushroom"] = timeUntilNewMushroom
	data["lastKeeper"] = lastKeeper
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	hasMushroom = data["hasMushroom"]
	timeUntilNewMushroom = data["timeUntilNewMushroom"]
	lastKeeper = data["lastKeeper"]
	if not hasMushroom:
		find_child("Mushroom").visible = false
	if currentState == State.REVEALED:
		find_child("AmbSound").play()
	
func _process(delta):
	if GameWorld.softPaused():
		return
	
	if timeUntilNewMushroom > 0.0:
		timeUntilNewMushroom -= delta
		if timeUntilNewMushroom <= 0.0:
			hasMushroom = true
			find_child("Mushroom").visible = true

func onRevealed():
	find_child("AmbSound").play()

func canFocusUse(keeper:Keeper) -> bool:
	return hasMushroom

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	if not hasMushroom:
		return false
	
	$MushroomConsumedSound.play()
	find_child("Mushroom").visible = false
	hasMushroom = false
	lastKeeper = keeper.playerId
	var cycleTime = GameWorld.getTimeBetweenWaves()
	keeper.addTemporaryBuff("keeper.speedbuff", speedBuffAmount, cycleTime * 0.6, "mushroomcave")
	timeUntilNewMushroom = cycleTime * 2.0
	return true
