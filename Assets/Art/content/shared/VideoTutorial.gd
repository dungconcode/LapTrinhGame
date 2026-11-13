extends Tutorial

var stage := 1

func _ready():
	super._ready()
	trigger()
	find_child("Text2").visible = false
	find_child("Text3").visible = false
	find_child("BackButton").disabled = true

func _on_VideoPlayer_finished():
	find_child("VideoPlayer").play()

func _on_Button_pressed():
	Audio.sound("gui_select")
	if stage < 3:
		stage += 1
		updatePlayers()
	else:
		confirm()

func updatePlayers():
	for i in range(1, 4):
		var player = find_child("VideoPlayer"+str(i))
		if i == stage:
			player.paused = false
			player.play()
		elif i < stage:
			player.paused = true
	find_child("Text"+str(stage)).visible = true
	find_child("BackButton").disabled = stage == 1

func onMovedIn():
	#wait for pause menu to close before talking over input	
	if Level.stage.pauseMenuOpen:
		Level.stage.pauseMenuOpenChanged.connect(onPauseMenuOpenInMoveIn)
	else:
		createInputAndStart()

func onPauseMenuOpenInMoveIn():
	if !Level.stage.pauseMenuOpen:
		Level.stage.pauseMenuOpenChanged.disconnect(onPauseMenuOpenInMoveIn)
		createInputAndStart()

func createInputAndStart():
	InputSystem.grabFocus(find_child("Button"))
	popupInput = preload("res://gui/PopupInput.gd").new()
	popupInput.popup = self
	popupInput.canClose = false
	popupInput.blockAllKeys = true
	popupInput.focusControlOnLeaf = get_viewport().gui_get_focus_owner()
	popupInput.integrate(Level.stage)
	find_child("VideoPlayer1").play()

func _on_VideoPlayer1_finished():
	find_child("VideoPlayer1").play()

func _on_VideoPlayer2_finished():
	find_child("VideoPlayer2").play()

func _on_VideoPlayer3_finished():
	find_child("VideoPlayer3").play()

func showAllVideos():
	find_child("VideoPlayer1").play()
	find_child("VideoPlayer2").play()
	find_child("VideoPlayer3").play()
	find_child("Text1").show()
	find_child("Text2").show()
	find_child("Text3").show()
	find_child("HSeparator").hide()
	find_child("Controls").hide()
	find_child("TitleLabel").hide()

func _on_BackButton_pressed():
	if stage > 1:
		Audio.sound("gui_select")
		stage -= 1
		updatePlayers()
	else:
		Audio.sound("gui_err")
