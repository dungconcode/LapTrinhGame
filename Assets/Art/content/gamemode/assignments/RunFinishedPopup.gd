extends Container

var isIn := false
var animationDone := false

func init(assignment:Assignment):
	if GameWorld.won:
		find_child("TitleLabel").text = "level.gameover.assignment.win.title"
	else:
		find_child("TitleLabel").text = "level.gameover.assignment.lose.title"
	
	var isChallengeMode = Data.of("assignment.challengemode")
	if isChallengeMode:
		%AssignmentTypeLabel.text = tr("assignment." + assignment.id + ".title") + " - " + tr("assignment.mode.challenge")
	else:
		%AssignmentTypeLabel.text = tr("assignment." + assignment.id + ".title") + " - " + tr("assignment.mode.regular")
		
	if GameWorld.won:
		%RestartRunButton.visible = false
		if GameWorld.unlockableElements.size() > 0:
			%MainMenuButton.visible = false
			%UnlockElementButton.visible = true
			%AnotherRunButton.visible = false
		else:
			%UnlockElementButton.visible = false
			%AnotherRunButton.visible = true
		
		var progress = GameWorld.assignmentProgress.get(assignment.id, 0)
		if progress == 2:
			%NewBadgesLabel.visible = false
		else:
			%NewBadgesLabel.text  = ""
			var earned:int = ((2 if isChallengeMode else 1) - progress)
			if earned > 0:
				%NewBadgesLabel.text = tr("level.gameover.assignment.badges")
			if progress < 2 and not isChallengeMode:
				%NewBadgesLabel.text += "\n" + tr("level.gameover.assignment.badges.more")
			GameWorld.assignmentProgress[assignment.id] = progress + earned
		%ExplanationLabel.text = tr("level.gameover.assignment.completed")
	else:
		%RestartRunButton.visible = true
		%AnotherRunButton.visible = false
		%UnlockElementButton.visible = false
		%ExplanationLabel.text = tr("level.gameover.assignment.failed")
		if assignment.goalvalue is PropertyCheck and assignment.goalvalue.property_key.ends_with("contribution"):
			var resource = assignment.goalvalue.property_key.replace("assignments.", "").replace("contribution", "")
			var goal:String = tr("assignment.condition.deliver" + resource) % assignment.goalvalue.expected_value
			%NewBadgesLabel.text = tr("assignment.goaltype.delivery.failed").format({"goal": goal, "amount": str(Data.of("assignments." + resource + "contribution"))})
		else:
			%NewBadgesLabel.visible = false
	
	SaveGame.persistMetaState()
	
	find_child("RunStats").init(self)
	
	if not Data.ofOr("postrun.showmine", false):
		find_child("MineViewButton").visible = false
	
	Style.init(self)

func updateFocus():
	if %AnotherRunButton.visible:
		InputSystem.grabFocus(%AnotherRunButton)
	elif %UnlockElementButton.visible:
		InputSystem.grabFocus(%UnlockElementButton)
	elif %RestartRunButton.visible:
		InputSystem.grabFocus(%RestartRunButton)

func moveIn():
	if isIn:
		return
	
	Level.stage.pause(false)
	GameWorld.setShowMouse(Options.useMouseMenus)
	isIn = true
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "position:y", position.y, (get_viewport_rect().size.y-size.y)*0.5, 1.2, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, 1.3, "set", "animationDone", true)
	$Tween.interpolate_callback(self, 2.5, "updateFocus")
	$Tween.start()

func _on_MainMenuButton_pressed():
	if isIn:
		continuePressed()
		if GameWorld.buildType == CONST.BUILD_TYPE.EXHIBITION:
			StageManager.startStage("stages/loadout/multiplayerloadout")
		else:
			StageManager.startStage("stages/demo/demo")

func _on_AnotherRunButton_pressed():
	if isIn:
		continuePressed()
		StageManager.startStage("stages/demo/demo")

func _on_restart_run_button_pressed() -> void:
	if isIn:
		continuePressed()
		var startData = LevelStartData.new()
		startData.loadout = Level.loadout.asLoadout()
		StageManager.startStage("stages/landing/landing", [startData])

func _on_MineViewButton_pressed():
	if isIn:
		Level.stage.startMineView()

func continuePressed():
	Audio.stopMusic()
	Audio.sound("gui_select")
	find_child("MainMenuButton").disabled = true
	%AnotherRunButton.disabled = true
	find_child("MineViewButton").disabled = true
	%RestartRunButton.disabled = true
	%UnlockElementButton.disabled = true

func focusMineViewButton():
	InputSystem.grabFocus(find_child("MineViewButton"))


func _on_unlock_element_button_pressed() -> void:
	Audio.sound("gui_select")
	var i = preload("res://gui/PopupInput.gd").new()
	var unlockablesPopup = preload("res://content/gamemode/unlockables/UnlockablesPopup.tscn").instantiate()
	unlockablesPopup.connect("proceed", i.desintegrate)
	unlockablesPopup.connect("back", i.desintegrate)
	unlockablesPopup.connect("back", updateFocus)
	unlockablesPopup.connect("back", unlockablesPopup.queue_free)
	get_parent().add_child(unlockablesPopup)
	i.popup = unlockablesPopup
	i.integrate(Level.stage)
