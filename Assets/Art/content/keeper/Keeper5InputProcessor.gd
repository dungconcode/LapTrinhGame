extends "res://content/keeper/KeeperInputProcessor.gd"

var pickupKeyDown := false
var pickupHold := false
var pickupKeyDownTime := 0.0
var pickupKeyCooldown := 0.0

var dropKeyDown := false
var dropHold := false
var dropKeyDownTime := 0.0
var dropKeyCooldown := 0.0

func _process(delta):
	super._process(delta)
	if GameWorld.paused:
		return
	
	if pickupKeyDown:
		pickupKeyDownTime += delta
		if pickupKeyDownTime > 0.3:
			keeper.pickupHold()
			pickupHold = true
			# intentional getting shorter
			pickupKeyDownTime -= pickupKeyCooldown
			pickupKeyCooldown = max(0.06, pickupKeyCooldown * 0.6)
	else:
		pickupKeyCooldown = 0.25
	
	if dropKeyDown:
		dropKeyDownTime += delta
		if dropKeyDownTime > 0.3:
			keeper.dropHold()
			dropHold = true
			# intentional getting shorter
			dropKeyDownTime -= dropKeyCooldown
			dropKeyCooldown = max(0.05, dropKeyCooldown * 0.6)
	else:
		dropKeyCooldown = 0.25

func keeperButtonEvent(event, handled:bool):
	if justPressed(event, "keeper1_pickup"):
		pickupKeyDownTime = 0.0
		pickupKeyDown = true
	elif justPressed(event, "keeper1_drop"):
		dropKeyDownTime = 0.0
		dropHold = false
		dropKeyDown = true
	
	if released(event, "keeper1_pickup"):
		if pickupKeyDown:
			pickupKeyDown = false
			if pickupHold:
				keeper.pickupHoldStopped()
				pickupHold = false
			elif not handled and not GameWorld.paused:
				keeper.pickupHit()
				pickupKeyDownTime = 0.0
	elif released(event, "keeper1_drop"):
		if dropKeyDown:
			dropKeyDown = false
			if not handled and not dropHold and not GameWorld.paused:
				keeper.dropHit()
				dropKeyDownTime = 0.0
