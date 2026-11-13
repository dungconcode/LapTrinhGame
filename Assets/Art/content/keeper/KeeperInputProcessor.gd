extends InputProcessor

signal escape

var leftStickMove := Vector2()
var rightStickMove := Vector2()

var leftKeyDown := false
var rightKeyDown := false
var upKeyDown := false
var downKeyDown := false

var useKeyDown := false
var useHold := false
var useHoldHandled := false
var useKeyDownTime := 0.0
var useKeyCooldown := 0.0

var keeper
var playerId:String

var runningInLoadout := false

func _ready():
	stopWithPredecessor = false

func _process(delta):
	if GameWorld.paused or desintegrating:
		return
	
	if useKeyDown:
		useKeyDownTime += delta
		if useKeyDownTime > 0.3:
			useHoldHandled = keeper.useHold()
			useHold = true
			# intentional getting shorter
			useKeyDownTime -= useKeyCooldown
			useKeyCooldown = max(0.05, useKeyCooldown * 0.6)
	else:
		useKeyCooldown = 0.25

func notLeaf():
	clearInput()

func becameLeaf():
	tryRestorInput()
	
func tryRestorInput():
	if Options.useGamepad:
		leftStickMove.x = convertGamepadAxisInput(Input.get_joy_axis(0, JOY_AXIS_LEFT_X))
		leftStickMove.y = convertGamepadAxisInput(Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
		rightStickMove.x = convertGamepadAxisInput(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X))
		rightStickMove.y = convertGamepadAxisInput(Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
		processStickMove()
	else:
		leftKeyDown = Input.is_action_pressed("ui_left")
		rightKeyDown = Input.is_action_pressed("ui_right")
		upKeyDown = Input.is_action_pressed("ui_up")
		downKeyDown =Input.is_action_pressed("ui_down")
		
		var md := calculateMoveDirection()
		if keeper and is_instance_valid(keeper):
			keeper.moveDirectionInput = md


func clearInput():
	leftKeyDown = false
	rightKeyDown = false
	upKeyDown = false
	downKeyDown = false
	useKeyDown = false
	useHold = false
	useHoldHandled = false
	useKeyDownTime = 0.0
	leftStickMove = Vector2()
	rightStickMove = Vector2()
	if keeper and is_instance_valid(keeper):
		keeper.moveDirectionInput.x = 0
		keeper.moveDirectionInput.y = 0
		keeper.aimDirectionInput.x = 0
		keeper.aimDirectionInput.y = 0

func handleStop():
	notLeaf()

func buttonEvent(event) -> bool:
	var handled := true
	if keeper == null:
		return false
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
		useHoldHandled = false
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
				handled = keeper.useHit()
				useKeyDownTime = 0.0
			else:
				handled = false
	elif justPressed(event, "escape"):
		Level.stage.openPauseMenu(Keepers.getDeviceId(keeper.playerId))
	elif justPressed(event, "pause"):
		if not Level.stage.pauseMenuOpen:
			if GameWorld.paused:
				if Level.stage.pausedByPlayer:
					Level.stage.unpause(true)
			else:
				Level.stage.pause(true)
	else:
		handled = false
	
	keeperButtonEvent(event, handled)
	
	if justPressed(event, "keeper_gadget1"):
		for s in get_tree().get_nodes_in_group("special1"):
			var consumed = s.executeSpecial1(keeper)
			if consumed:
				break
	elif justPressed(event, "keeper_gadget2"):
		for s in get_tree().get_nodes_in_group("special2"):
			var consumed = s.executeSpecial2(keeper)
			if consumed:
				break
	elif justPressed(event, "cheats"):
		# so the parent input processor can deal with this
		return false
	elif justPressed(event, "escape"):
		return false
	
	if desintegrating:
		return true

	var md := calculateMoveDirection()
	if keeper:
		keeper.moveDirectionInput = md
	if Options.useGamepad and not Options.twinStickControls:
		if keeper:
			keeper.aimDirectionInput = md
	return md.length() > 0 or handled

func calculateMoveDirection() -> Vector2:
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
	return md

func onUserTabbedOut():
	clearInput()
	
func onPaused():
	clearInput()
	pass

func keeperButtonEvent(event, handled:bool):
	pass

func convertGamepadAxisInput(axis_value) -> float:
	if abs(axis_value) <= Options.gamepadStickDeadZone:
		return 0.0
	else:
		return (axis_value-(sign(axis_value)*Options.gamepadStickDeadZone)) * (1.0 / (1.0 - Options.gamepadStickDeadZone))

	
func stick_move(event:InputEventJoypadMotion) -> bool:
	var value = convertGamepadAxisInput(event.axis_value)
	match event.axis:
		JOY_AXIS_LEFT_X:
			leftStickMove.x = value
		JOY_AXIS_LEFT_Y:
			leftStickMove.y = value
		JOY_AXIS_RIGHT_X:
			rightStickMove.x = value
		JOY_AXIS_RIGHT_Y:
			rightStickMove.y = value
		_:
			return false

	processStickMove()

	return true

func processStickMove():
	if not keeper:
		return
	
	if not(rightKeyDown or leftKeyDown or upKeyDown or downKeyDown):
		var left = Vector2(leftStickMove.x, leftStickMove.y)
		if left.length() > 1.0:
			left = left.normalized()

		var right = Vector2(rightStickMove.x, rightStickMove.y)
		if right.length() > 1.0:
			right = right.normalized()

		keeper.moveDirectionInput = left
		if Options.twinStickControls:
			keeper.aimDirectionInput = right
		else:
			keeper.aimDirectionInput = left
	elif Options.twinStickControls:
		var right = Vector2(rightStickMove.x, rightStickMove.y)
		if right.length() > 1.0:
			right = right.normalized()
		keeper.aimDirectionInput = right
