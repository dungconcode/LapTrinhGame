extends CanvasLayer

signal close

var closed := false
var saveOnQuit := true

func _ready():
	$ColorRect.color = Style.OVERLAY_COLOR_OUT
	fadeIn(0.3)
	$VersionBox/VersionLabel.text = GameWorld.getVersionPrint()
	if GameWorld.qaOptions or GameWorld.devMode:
		$VersionBox/VersionLabel.gui_input.connect(copy_version_to_clipboard)
	Style.init(self)
	%ButtonRestartRun.visible = Level.stage is LevelStage
	
	if GameWorld.buildType == CONST.BUILD_TYPE.EXHIBITION:
		$BippinbitsBox.visible = false
		if not GameWorld.devMode:
			find_child("ButtonOptions").visible = false
			find_child("ButtonQuitGame").visible = false
	
	update_supportbox()

func copy_version_to_clipboard(ev):
	if ev is InputEventMouseButton:
		DisplayServer.clipboard_set(GameWorld.getVersionPrint())

func onInputMethodChanged():
	update_supportbox()

func update_supportbox():
	if Keepers.oneInsideDome():
		$SupportBox/PanelContainer/VBoxContainer/Dome.show()
		$SupportBox/PanelContainer/VBoxContainer/Mine.hide()
	else:
		$SupportBox/PanelContainer/VBoxContainer/Dome.hide()

	if Keepers.oneInsideMine():
		$SupportBox/PanelContainer/VBoxContainer/Mine.show()
	else:
		$SupportBox/PanelContainer/VBoxContainer/Mine.hide()

	if Options.useGamepad:
		match Options.getGamepadName():
			"playstation":
				$SupportBox/PanelContainer/VBoxContainer/Gamepad.texture = preload("res://gui/gamepad_controller_ps4.png")
			_:
				$SupportBox/PanelContainer/VBoxContainer/Gamepad.texture = preload("res://gui/gamepad_controller.png")
		$SupportBox/PanelContainer/VBoxContainer/Gamepad.show()
		$SupportBox/PanelContainer/VBoxContainer/Keyboard.hide()
		$SupportBox/PanelContainer/VBoxContainer/Mouse.hide()
		get_tree().call_group("hide_for_gamepad", "hide")
	elif Options.useMouseKeeperGameplay or Options.useMouseDomeGameplay:
		$SupportBox/PanelContainer/VBoxContainer/Mouse.show()
		$SupportBox/PanelContainer/VBoxContainer/Gamepad.hide()
		$SupportBox/PanelContainer/VBoxContainer/Keyboard.hide()
	else:
		$SupportBox/PanelContainer/VBoxContainer/Gamepad.hide()
		$SupportBox/PanelContainer/VBoxContainer/Keyboard.show()
		$SupportBox/PanelContainer/VBoxContainer/Mouse.hide()
		get_tree().call_group("hide_for_gamepad", "show")

func _on_ButtonDiscord_pressed() -> void:
	Audio.sound("gui_select")
	OS.shell_open("https://discord.gg/AxYpX7AaFP")

func _on_ButtonOptions_pressed() -> void:
	Audio.sound("gui_select")
	var i = preload("res://systems/options/OptionsInputProcessor.gd").new()
	i.blockAllKeys = true
	i.popup = preload("res://systems/options/OptionsPanel.tscn").instantiate()
	i.stickReceiver = i.popup
	add_child(i.popup)
	i.popup.setFromOptions()
	i.integrate(self)
	i.connect("onStop", Callable(self, "optionsClosed").bind(i.popup))
	i.popup.connect("close", Callable(i, "desintegrate"))

func optionsClosed(popup):
	InputSystem.grabFocus(find_child("ButtonResume"))
	remove_child(popup)
	popup.queue_free()

func _on_ButtonBackToTitle_pressed() -> void:
	if find_child("ReallyQuitToTitlePopup").visible:
		Audio.sound("gui_quit_confirm")
		if saveOnQuit and not Data.of("monsters.wavepresent"):
			SaveGame.saveGame(0)
		closed = true
		if GameWorld.buildType == CONST.BUILD_TYPE.EXHIBITION:
			StageManager.startStage("stages/loadout/multiplayerloadout")
		else:
			StageManager.startStage("stages/title/title")
		find_child("ButtonBackToTitle").disabled = true
		find_child("ButtonQuitGame").disabled = true
	else:
		Audio.sound("gui_quit_ask")
		enterQuitConfirmation()

func _on_ButtonQuitGame_pressed() -> void:
	if find_child("ReallyQuitToTitlePopup").visible:
		Audio.sound("gui_quit_confirm")
		if saveOnQuit and not Data.of("monsters.wavepresent"):
			SaveGame.saveGame(0)
		closed = true
		Backend.event("game_quit")
		Backend.sendBufferedEvents()
		$Tween.interpolate_callback(get_tree(), 0.4, "quit")
		$Tween.start()
		find_child("ButtonBackToTitle").disabled = true
		find_child("ButtonQuitGame").disabled = true
	else:
		Audio.sound("gui_quit_ask")
		enterQuitConfirmation()

func enterQuitConfirmation():
	var p = find_child("ReallyQuitToTitlePopup")
	p.modulate.a = 0
	p.visible = true
	var causingButton = find_child("ButtonBackToTitle")
	p.position.x = causingButton.size.x + 30
	var d = (1.0-p.modulate.a) * 0.2
	$ConfirmationTween.stop_all()
	$ConfirmationTween.remove_all()
	$ConfirmationTween.interpolate_property(p, "modulate:a", p.modulate.a, 1.0, d, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$ConfirmationTween.start()

func _on_button_restart_run_pressed() -> void:
	if %ReallyRestartPopup.visible:
		closed = true
		Backend.event("game_restarted")
		Backend.sendBufferedEvents()
		var startData = LevelStartData.new()
		startData.loadout = Level.loadout.asLoadout()
		if GameWorld.buildType == CONST.BUILD_TYPE.EXHIBITION:
			startData.tileDataPresetId = "Exhibition"
		Level.randomizeSeed()
		Audio.sound("gui_quit_confirm")
		Audio.stopMusic()
		Audio.unmuteSounds()
		StageManager.startStage("stages/landing/landing", [startData])
		find_child("ButtonRestartRun").disabled = true
	else:
		Audio.sound("gui_quit_ask")
		%ReallyRestartPopup.modulate.a = 0
		%ReallyRestartPopup.visible = true
		%ReallyRestartPopup.position.x = %ButtonRestartRun.size.x + 30
		var d = (1.0 - %ReallyRestartPopup.modulate.a) * 0.2
		$ConfirmationTween.stop_all()
		$ConfirmationTween.remove_all()
		$ConfirmationTween.interpolate_property(%ReallyRestartPopup, "modulate:a", %ReallyRestartPopup.modulate.a, 1.0, d, Tween.TRANS_QUAD, Tween.EASE_OUT)
		$ConfirmationTween.start()

func hideRestartConfirmation() -> void:
	if closed:
		return
	
	if not %ReallyRestartPopup.visible:
		return
	
	var d = %ReallyRestartPopup.visible.modulate.a * 0.2
	$ConfirmationTween.stop_all()
	$ConfirmationTween.remove_all()
	$ConfirmationTween.interpolate_property(%ReallyRestartPopup.visible, "modulate:a", %ReallyRestartPopup.visible.modulate.a, 0.0, d, Tween.TRANS_QUAD, Tween.EASE_IN)
	$ConfirmationTween.interpolate_callback(%ReallyRestartPopup.visible, d, "set", "visible", false)
	$ConfirmationTween.start()

func exitQuitConfirmation():
	if closed:
		return
	
	var p = find_child("ReallyQuitToTitlePopup")
	if not p.visible:
		return
	
	var d = p.modulate.a * 0.2
	$ConfirmationTween.stop_all()
	$ConfirmationTween.remove_all()
	$ConfirmationTween.interpolate_property(p, "modulate:a", p.modulate.a, 0.0, d, Tween.TRANS_QUAD, Tween.EASE_IN)
	$ConfirmationTween.interpolate_callback(p, d, "set", "visible", false)
	$ConfirmationTween.start()

func _on_ButtonResume_pressed() -> void:
	Audio.sound("gui_back")
	emit_signal("close")

func fadeIn(t:float):
	Audio.sound("gui_pause_start")
	Audio.muteSounds()
	find_child("ReallyQuitToTitlePopup").visible = false
	%ReallyRestartPopup.visible = false
	
	$MenuPanel.pivot_offset = $MenuPanel.size * 0.5
	$MenuPanel.scale = Vector2.ZERO
	$Tween.interpolate_property($ColorRect, "color", $ColorRect.color, Style.OVERLAY_COLOR_IN, t*0.5)
	$Tween.interpolate_property($MenuPanel, "scale", Vector2.ZERO, Vector2.ONE, t, Tween.TRANS_CUBIC)
	
	var d = $SupportBox.size.x * 1.5
	$SupportBox.position.x -= d
	$Tween.interpolate_property($SupportBox, "position", $SupportBox.position, $SupportBox.position + Vector2(d,0), t*2, Tween.TRANS_CUBIC)
	
	d = $VersionBox.size.x * 1.5
	$VersionBox.position.x -= d
	$Tween.interpolate_property($VersionBox, "position", $VersionBox.position, $VersionBox.position + Vector2(d,0), t*2, Tween.TRANS_CUBIC)
	
	d = $BippinbitsBox.size.x * 1.2
	$BippinbitsBox.position.x += d
	$Tween.interpolate_property($BippinbitsBox, "position", $BippinbitsBox.position, $BippinbitsBox.position - Vector2(d,0), t*2, Tween.TRANS_CUBIC)
	
	d = $GodotBox.size.x
	$GodotBox.position.x += d
	$Tween.interpolate_property($GodotBox, "position", $GodotBox.position, $GodotBox.position - Vector2(d,0), t*2, Tween.TRANS_CUBIC)
	
	$Tween.interpolate_callback(InputSystem, t, "grabFocus", find_child("ButtonResume"))
	$Tween.start()

func fadeOut(t:float):
	Audio.sound("gui_pause_stop")
	Audio.unmuteSounds()
	closed = true
	$Tween.interpolate_property($ColorRect, "color", $ColorRect.color, Style.OVERLAY_COLOR_OUT, t*0.5, Tween.TRANS_LINEAR,Tween.EASE_IN_OUT, t*0.5)
	$Tween.interpolate_property($MenuPanel, "scale", $MenuPanel.scale , Vector2.ZERO, t, Tween.TRANS_CUBIC, Tween.EASE_OUT)

	var d = $SupportBox.size.x
	$Tween.interpolate_property($SupportBox, "position", $SupportBox.position, $SupportBox.position - Vector2(d,0), t, Tween.TRANS_CUBIC)
	
	d = $VersionBox.size.x
	$Tween.interpolate_property($VersionBox, "position", $VersionBox.position, $VersionBox.position - Vector2(d,0), t, Tween.TRANS_CUBIC)
	
	d = $BippinbitsBox.size.x
	$Tween.interpolate_property($BippinbitsBox, "position", $BippinbitsBox.position, $BippinbitsBox.position + Vector2(d,0), t, Tween.TRANS_CUBIC)
	
	d = $GodotBox.size.x
	$Tween.interpolate_property($GodotBox, "position", $GodotBox.position, $GodotBox.position + Vector2(d,0), t, Tween.TRANS_CUBIC)
	
#	$Tween.interpolate_callback(self.get_parent(), t, "remove_child", self)
	$Tween.interpolate_callback(self, t, "queue_free")
	
	$Tween.start()

func _on_ButtonTutorials_pressed():
	Audio.sound("gui_select")
	var i = preload("res://content/shared/ControllerScrollInputProcessor.gd").new()
	i.popup = preload("res://systems/tutorials/AllTutorialsPopup.tscn").instantiate()
	i.scrollTarget = i.popup.find_child("ScrollContainer").get_v_scroll_bar()
	add_child(i.popup)
	i.integrate(self)
	i.connect("onStop", Callable(self, "tutorialPopupClosed").bind(i.popup))

func tutorialPopupClosed(popup):
	InputSystem.grabFocus(find_child("ButtonTutorials"))
	remove_child(popup)
	popup.queue_free()
