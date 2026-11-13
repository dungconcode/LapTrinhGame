extends InputProcessor

signal escape

var leftStickMove := Vector2()

var leftKeyDown := false
var rightKeyDown := false
var upKeyDown := false
var downKeyDown := false

var useKeyDown := false
var useHold := false
var useKeyDownTime := 0.0
var useKeyCooldown := 0.0

var playerId:String
var keeper

func _ready():
	stopWithPredecessor = false

func _process(delta):
	if GameWorld.paused or desintegrating:
		return
	
	if useKeyDown:
		useKeyDownTime += delta
		if useKeyDownTime > 0.3:
			keeper.setDrillDown(true)
			useHold = true
			# intentional getting shorter
			useKeyDownTime -= useKeyCooldown
			useKeyCooldown = max(0.05, useKeyCooldown * 0.6)
	else:
		useKeyCooldown = 0.25
		keeper.setDrillDown(false)

func becameLeaf():
	notLeaf()
	GameWorld.setShowMouse(false)

func notLeaf():
	leftKeyDown = false
	rightKeyDown = false
	upKeyDown = false
	downKeyDown = false
	useKeyDown = false
	useHold = false
	useKeyDownTime = 0.0
	if keeper:
		keeper.moveDirectionInput.x = 0
		keeper.moveDirectionInput.y = 0

func handleStart():
	keeper.moveDirectionInput = Vector2()
	

func handleStop():
	notLeaf()

func buttonEvent(event) -> bool:
	if pressed(event, "ui_left"):
		leftKeyDown = true
	elif pressed(event, "ui_right"):
		rightKeyDown = true
	elif pressed(event, "ui_up"):
		upKeyDown = true
	elif pressed(event, "ui_down"):
		downKeyDown = true
	elif justPressed(event, "ui_select"):
		useKeyDownTime = 0.0
		useHold = false
		useKeyDown = true
	elif justPressed(event, "cheats"):
		Level.stage.toggleCheats()
	elif released(event, "ui_left"):
		leftKeyDown = false
	elif released(event, "ui_right"):
		rightKeyDown = false
	elif released(event, "ui_up"):
		upKeyDown = false
	elif released(event, "ui_down"):
		downKeyDown = false
	elif released(event, "ui_select"):
		if useKeyDown:
			useKeyDown = false
			if not useHold and not GameWorld.paused:
				keeper.jump()
				useKeyDownTime = 0.0
	elif justPressed(event, "escape"):
		Level.stage.openPauseMenu(Keepers.getDeviceId(keeper.playerId))
		return true
	elif justPressed(event, "pause"):
		if GameWorld.paused:
			Level.stage.unpause(true)
		else:
			Level.stage.pause(true)
		return true

	elif justPressed(event, "cheats"):
		# so the parent input processor can deal with this
		return false
	elif justPressed(event, "escape"):
		return false
	
	var md := Vector2()
	if leftKeyDown:
		md.x -= 1
	if rightKeyDown:
		md.x += 1
	if upKeyDown:
		md.y -= 1
	if downKeyDown:
		md.y += 1

	if md.length() == 0:
		md += leftStickMove
	elif md.length() > 1.0:
		md = md.normalized()
	keeper.moveDirectionInput = md
	return md.length() > 0

func stick_move(event:InputEventJoypadMotion) -> bool:
	match event.axis:
		0:
			if abs(event.axis_value) <= Options.gamepadStickDeadZone:
				leftStickMove.x = 0
			else:
				leftStickMove.x = (event.axis_value-(sign(event.axis_value)*Options.gamepadStickDeadZone)) * (1.0 / (1.0 - Options.gamepadStickDeadZone))
		1:
			if abs(event.axis_value) <= Options.gamepadStickDeadZone:
				leftStickMove.y = 0
			else:
				leftStickMove.y = (event.axis_value-(sign(event.axis_value)*Options.gamepadStickDeadZone)) * (1.0 / (1.0 - Options.gamepadStickDeadZone))
		_:
			return false

	processStickMove()

	return true

func processStickMove():
	if not(rightKeyDown or leftKeyDown or upKeyDown or downKeyDown):
		var md = Vector2(leftStickMove.x, leftStickMove.y)
		if md.length() > 1.0:
			md = md.normalized()

		keeper.moveDirectionInput = md
