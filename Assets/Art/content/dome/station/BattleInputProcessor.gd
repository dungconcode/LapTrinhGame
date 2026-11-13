extends InputProcessor

var stickMove := Vector2()
var leftKeyDown := false
var rightKeyDown := false
var downKeyDown := false
var upKeyDown := false
var fireValue := 0.0
var specialValue := 0.0

var domeId:String

var popup 

var controlledWeapons:Array

func _ready():
	stopSuccessors = false

func notLeaf():
	if successor and successor is InputProcessor:
		return
	
	clearInput()

func clearInput():
	leftKeyDown = false
	rightKeyDown = false
	downKeyDown = false
	upKeyDown = false
	fireValue = 0.0
	specialValue = 0.0
	stickMove = Vector2()

func onUserTabbedOut():
	clearInput()

func becameLeaf():
	GameWorld.setShowMouse(Options.useMouseDomeGameplay)
	InputSystem.changeCursor("crosshairs")

func handleStart():
	popup.moveIn(true)
	Audio.sound("charge_on_" + Level.domeId())
	for weapon in controlledWeapons:
		weapon.start()
	for listener in get_tree().get_nodes_in_group("battle-start-stop-listener"):
		listener.start()

func handleStop():
	popup.moveOut(-1)
	Audio.sound("charge_off_" + Level.domeId())
	for weapon in controlledWeapons:
		weapon.inputs(Vector2.ZERO, 0.0, 0.0)
		weapon.stop()
	for listener in get_tree().get_nodes_in_group("battle-start-stop-listener"):
		listener.stop()

func buttonEvent(event) -> bool:
	if pressed(event, "ui_left"):
		leftKeyDown = true
	if pressed(event, "ui_right"):
		rightKeyDown = true
	if pressed(event, domeId + "_fire"):
		fireValue = 1.0
	if pressed(event, domeId + "_special"):
		specialValue = 1.0
	if pressed(event, "ui_down"):
		downKeyDown = true
	if pressed(event, "ui_up"):
		upKeyDown = true
	if justPressed(event, "ui_cancel"):
		desintegrate()
	if released(event, "ui_left"):
		leftKeyDown = false
	if released(event, "ui_right"):
		rightKeyDown = false
	if released(event, domeId + "_fire"):
		fireValue = 0.0
	if released(event, domeId + "_special"):
		specialValue = 0.0
	if released(event, "ui_down"):
		downKeyDown = false
	if released(event, "ui_up"):
		upKeyDown = false
	if justPressed(event, "cheats"):
		# so the parent input processor can deal with this
		return false
	if justPressed(event, "escape"):
		return false
	if justPressed(event, "dome_ability1"):
		for s in get_tree().get_nodes_in_group("dome_ability1"):
			var consumed = s.executeBattle1()
			if consumed:
				break
	if justPressed(event, "dome_ability2"):
		for s in get_tree().get_nodes_in_group("dome_ability2"):
			var consumed = s.executeBattle2()
			if consumed:
				break
	
	return true

func stick_move(event:InputEventJoypadMotion) -> bool:
	if event.axis == 0: # left stick horizontal
		if abs(event.axis_value) <= Options.gamepadStickDeadZone:
			stickMove.x = 0
		else:
			stickMove.x = axisValueDeadzoned(event.axis_value, Options.gamepadStickDeadZone)
	elif event.axis == 1: # left stick vertical
		if abs(event.axis_value) <= Options.gamepadStickDeadZone:
			stickMove.y = 0
		else:
			stickMove.y = axisValueDeadzoned(event.axis_value, Options.gamepadStickDeadZone)
	
	if InputMap.event_is_action(event, domeId + "_fire"):
		fireValue = event_value(event)
	if InputMap.event_is_action(event, domeId + "_special"):
		specialValue = event_value(event)
	return true

func axisValueDeadzoned(axis_value, deadzone) -> float:
	var result = axis_value-(sign(axis_value)*deadzone)
	result *= 1.0 / (1.0 - deadzone)
	return result

func event_value(event): # only used for pressed events, not released
	if event is InputEventJoypadMotion:
		if event.axis <= 3: # 0 to 3 are sticks
			if abs(event.axis_value) > Options.gamepadStickDeadZone:
				return axisValueDeadzoned(event.axis_value, Options.gamepadStickDeadZone)
		elif event.axis == Options.AXIS_LT || event.axis == Options.AXIS_RT: # left and right trigger
			if abs(event.axis_value) > Options.gamepadTriggerDeadZone:
				return axisValueDeadzoned(event.axis_value, Options.gamepadTriggerDeadZone)
	elif event is InputEventJoypadButton:
		# cannot test event.pressure atm
		return event.pressure
	return 0.0

func _process(delta):
	var move := Vector2()
	if leftKeyDown:
		move.x -= 1
	if rightKeyDown:
		move.x += 1
	move.x = clamp(move.x + stickMove.x, -1.0, 1.0)


	if upKeyDown:
		move.y -= 1
	if downKeyDown:
		move.y += 1
	move.y = clamp(move.y + stickMove.y, -1.0, 1.0)

	for weapon in controlledWeapons:
		weapon.inputs(move, fireValue, specialValue)

