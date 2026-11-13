extends Node

var ending := false
var relicRetrievalStarted := false
var relicRetrieved := false
var relicTriggered := false
var maxD := 0.0
var mod2 := 0.0
var mod3 := 0.0
var musicPlaying := false
var maxDesperation := 0.0
var runWeightOverride := -1 # for control testing purposes

var relicRetrievalMusicType:String

var assignment:Assignment

func init():
	Data.listen(self, "dome.health")
	
	assignment = Data.assignments.get(Data.of("assignment.id"))
	
	if Data.ofOr("run.durationcycles", 0) > 0:
		Data.listen(self, "monsters.cycle")
	
	match assignment.goaltype:
		"relic":
			Data.listen(self, "inventory.floatingrelic")
			Data.listen(self, "inventory.relic")
		"property":
			Data.listen(self, assignment.goalvalue.property_key)

func afterInitialized():
	if Data.ofOr("game.fixedtimelimit", 0) > 0:
		var hud = preload("res://content/gamemode/assignments/FixedTimeLimitHud.tscn").instantiate()
		Level.addHudElement(hud)
	
	if Data.ofOr("run.durationcycles", 0) > 0:
		Data.apply("wavemeter.showcounter", true)
	
	var assignmentUpgrade = GameWorld.upgrades.get("assignments")
	GameWorld.upgrades["assignments"]["overwriteTitleKey"] = "assignment." + assignment.id + ".title"
	GameWorld.upgrades["assignments"]["overwriteDescKey"] = "assignment." + assignment.id + ".desc"

func propertyChanged(property:String, oldValue, newValue):
	if assignment.goalvalue and assignment.goalvalue.property_key == property:
		if assignment.goalvalue.fulfilled(Data.values):
			handlePropertyGoalGameEnd()
		return
	match property:
		"monsters.cycle": # only listending for "assignment.goaltype == survive"
			if SaveGame.currentLoadingSavegame:
				return
			
			if int(newValue) == int(Data.ofOr("run.durationcycles", -1)):
				match assignment.goaltype:
					"survive":
						SaveGame.allow_saving = false
						$ScriptTween.interpolate_callback(Level.monsters, 3.0, "startFinalAct")
						$ScriptTween.start()
						Data.listen(self, "monsters.wavepresent")
					"property":
						handlePropertyGoalGameEnd()
		"monsters.wavepresent": # only listen after end sequence is relicRetrievalStarted
			if relicRetrievalStarted:
				if not newValue:
					GameWorld.handleGameWon()
					
					Audio.stopBattleMusic()
					Level.stage.stopKeeperInput()
					Level.monsters.disabled = true
					fadeDesperationOut(true)
					
					await get_tree().create_timer(3.0).timeout
					
					Audio.startEnding()
					if not relicTriggered:
						Achievements.triggerIfOpen("RELICHUNT_BEATFINALE")
						if Level.loadout.keepers.front().keeperId == "keeper1":
							GameWorld.newSkinsToUnlock.append("skin2")
					
					await get_tree().create_timer(4.0).timeout
					
					var popup = preload("res://content/gamemode/assignments/RunFinishedPopup.tscn").instantiate()
					popup.init(assignment)
					Level.stage.showEndingPanel(popup)
					SaveGame.delete_autosave()
				else:
					$DesperationLayer1.volume_db = -60
					$DesperationLayer2.volume_db = -60
					$DesperationLayer1.play()
					$DesperationLayer2.play()
					$DesperationTween.interpolate_property($DesperationLayer1, "volume_db", -60, 0, 5.0)
					$DesperationTween.start()
			else:
				if not newValue:
					Level.moveHudOut()
					Level.stage.stopKeeperInput()
					Audio.startEnding()
					
					await get_tree().create_timer(3.0).timeout
					GameWorld.handleGameWon({"assignment-id": assignment.id})
					var popup = preload("res://content/gamemode/assignments/RunFinishedPopup.tscn").instantiate()
					popup.init(assignment)
					Level.stage.showEndingPanel(popup)
		"inventory.floatingrelic":
			relicRetrievalStarted = true
		"inventory.relic":
			if newValue == 1:
				SaveGame.allow_saving = false
				relicRetrieved = true
				$ScriptTween.interpolate_callback(Level.monsters, 3.0, "startFinalAct")
				$ScriptTween.start()
				Data.changeDomeHealth(Data.of("dome.maxHealth") - Data.of("dome.health"))
				Data.listen(self, "monsters.wavepresent")
				fadeRetrievalMusicOut()
		"dome.health":
			if not GameWorld.domeHealthLocked and newValue > 0:
				maxDesperation = min(maxDesperation, 1.0 - Data.of("dome.health") / float(Data.of("dome.maxhealth")))
				$DesperationLayer2.volume_db = -40 + 40 * maxDesperation
			else:
				fadeDesperationOut()
			
			if relicRetrieved and (newValue <= 0 and not (Data.of("inventory.sand") > 0 and Data.ofOr("dome.autorepair", false))) and not relicTriggered:
				relicTriggered = true
				Level.stage.getVignette().forceShow()
				GameWorld.domeHealthLocked = true
				var busIdx = AudioServer.get_bus_index(Audio.BUS_WORLD)
				var amplify:AudioEffectAmplify = AudioServer.get_bus_effect(busIdx, 0)
				amplify.volume_db = -9
				
				var bomb = load("res://content/gadgets/cobaltbomb/CobaltBomb.tscn").instantiate()
				Level.viewports.addElement(bomb)
				Level.monsters.disabled = true
				Level.stage.fadeOutTime = 2.5
				Data.unlisten(self, "dome.health")
				Audio.stopBattleMusic()
				Level.stage.stopKeeperInput()
				InputSystem.shake(80, 1, 8)
				
				var vignette = Level.stage.getVignette()
				vignette.setTarget(bomb.get_node("Orbs"))
				vignette.strengthStartY = -450
				vignette.strengthEndY = 1000
				$ScriptTween.interpolate_property(vignette, "strengthEndY", vignette.strengthEndY, -100, 1.0, Tween.TRANS_LINEAR, 0.0)
				$ScriptTween.interpolate_property(vignette, "strengthEndY", -100, vignette.strengthEndY, 2.5, Tween.TRANS_LINEAR, Tween.EASE_IN, 2.0)
				$ScriptTween.interpolate_callback(Data, 5.0, "apply", "monsters.wavepresent", false)
				$ScriptTween.start()
			elif newValue <= 0 and not GameWorld.lost:
				Level.moveHudOut()
				fadeDesperationOut()
				GameWorld.lost = true
				var delay = Level.stage.playGameLostAnimation()
				
				await get_tree().create_timer(delay).timeout
				Audio.sound("lose")
				await get_tree().create_timer(0.2).timeout
				GameWorld.handleGameLost()
				
				Audio.startGameOver(1.0)
				await get_tree().create_timer(5.0).timeout
				var popup = preload("res://content/gamemode/assignments/RunFinishedPopup.tscn").instantiate()
				popup.init(assignment)
				Level.stage.showEndingPanel(popup)

func handlePropertyGoalGameEnd():
	Level.moveHudOut()
	Level.stage.stopKeeperInput()
	
	if assignment.goalvalue.fulfilled(Data.values):
		Audio.startEnding()
		await get_tree().create_timer(2.5).timeout
		GameWorld.handleGameWon({"assignment-id": assignment.id})
	else:
		Audio.sound("lose")
		await get_tree().create_timer(2.5).timeout
		Level.dome.collapsed = true # prevent collapse
		GameWorld.handleGameLost()
		Keepers.first().visible = true

	var popup = preload("res://content/gamemode/assignments/RunFinishedPopup.tscn").instantiate()
	popup.init(assignment)
	Level.stage.showEndingPanel(popup)

func addCycleData(data:Dictionary):
	pass

func getRunWeight() -> float:
	var fixedWeight = Data.ofOr("monsters.fixedweight", -1)
	if fixedWeight >= 0:
		return float(fixedWeight)
	
	var weight := 10 + float(Data.ofOr("monsters.additionalwaveweight", 0))
	weight += Data.of("inventory.totaliron") * 0.6
	weight += Data.of("inventory.totalsand") * 2.2
	weight += Data.of("inventory.totalwater") * 1.2
	weight += Data.of("inventory.gadget") * 8
	var cycle = Data.of("monsters.cycle")
	var cycleWeight = round(cycle * ((9 + Level.loadout.difficulty) + cycle * 0.15)) + cycle * 2
	weight += cycleWeight * Data.of("monstermodifiers.cyclesrunweightmodifier")
	weight += GameWorld.additionalRunWeight
	weight *= 1.0 + Level.loadout.difficulty * 0.1
	return max(15, weight) * Data.of("monstermodifiers.totalrunweightmodifier")

func _process(delta):
	if not ending:
		var timeLimit = Data.ofOr("game.fixedtimelimit", 0)
		if timeLimit > 0 and timeLimit * 60 <= GameWorld.runTime:
			handlePropertyGoalGameEnd()
			ending = true
	
	if not relicRetrievalStarted:
		return
	
	var relics = get_tree().get_nodes_in_group("relic")
	if relics.size() == 0 or relicRetrieved:
		return
	
	var relic = relics.front()
	if maxD == 0.0:
		maxD = relic.global_position.length()
	
	if relic.isCarried():
		if not musicPlaying:
			var currentCarrier = relic.carriedBy.front().techId
			fadeRetrievalMusicIn(currentCarrier)
		$RelicRetrievalLayer1Loop.volume_db = -60 + 60 * mod3
		$RelicRetrievalLayer2Loop.volume_db = -60 + 60 * clamp(1.0 - (relic.global_position.length() - 500) / maxD, 0.0, 1.0) * mod2
	elif musicPlaying:
		fadeRetrievalMusicOut()

func fadeRetrievalMusicIn(currentCarrier:String):
	if currentCarrier != relicRetrievalMusicType:
		relicRetrievalMusicType = currentCarrier
		match relicRetrievalMusicType:
			"keeper1":
				$RelicRetrievalLayer1Intro.stream = preload("res://content/music/ENGINEER Relic Retrieval Layer 1 [intro].ogg")
				$RelicRetrievalLayer1Loop.stream = preload("res://content/music/ENGINEER Relic Retrieval Layer 1 [loop].ogg")
				$RelicRetrievalLayer2Loop.stream = preload("res://content/music/ENGINEER Relic Retrieval Layer 2 [loop].ogg")
				$DesperationLayer1.stream = preload("res://content/music/LASER Desperation Layer 1 [loop].ogg")
				$DesperationLayer2.stream = preload("res://content/music/LASER Desperation Layer 2 [loop].ogg")
			"keeper2":
				$RelicRetrievalLayer1Intro.stream = preload("res://content/music/ASSESSOR Relic Retrieval Layer 1 [intro].ogg")
				$RelicRetrievalLayer1Loop.stream = preload("res://content/music/ASSESSOR Relic Retrieval Layer 1 [loop].ogg")
				$RelicRetrievalLayer2Loop.stream = preload("res://content/music/ASSESSOR Relic Retrieval Layer 2 [loop].ogg")
				$DesperationLayer1.stream = preload("res://content/music/ASSESSOR Final Push Layer 1 [loop].ogg")
				$DesperationLayer2.stream = preload("res://content/music/ASSESSOR Final Push Layer 2 [loop].ogg")

	musicPlaying = true
	
	Audio.stopMusic()
	if not $RelicRetrievalLayer1Loop.playing:
		mod3 = 0.0
		$RelicRetrievalLayer1Intro.play()
		$RelicRetrievalLayer1Loop.play()
		$RelicRetrievalLayer2Loop.play()
	$MusicTween.interpolate_property($RelicRetrievalLayer1Intro, "volume_db", $RelicRetrievalLayer1Intro.volume_db, 0, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$MusicTween.interpolate_property(self, "mod2", 0.0, 1.0, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$MusicTween.start() 

func fadeRetrievalMusicOut(time := 4.0):
	musicPlaying = false
	$MusicTween.stop_all()
	$MusicTween.remove_all()
	$MusicTween.interpolate_property($RelicRetrievalLayer1Intro, "volume_db", $RelicRetrievalLayer1Intro.volume_db, -60, time, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$MusicTween.interpolate_property($RelicRetrievalLayer1Loop, "volume_db", $RelicRetrievalLayer1Loop.volume_db, -60, time, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$MusicTween.interpolate_property($RelicRetrievalLayer2Loop, "volume_db", $RelicRetrievalLayer2Loop.volume_db, -60, time, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$MusicTween.interpolate_property(self, "mod2", mod2, 0.0, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$MusicTween.start() 

func _on_RelicRetrievalLayer1Intro_finished():
	if not GameWorld.gameover:
		$RelicRetrievalLayer1Loop.volume_db = 0.0
		mod3 = 1.0

func fadeDesperationOut(force := false):
	if force:
		$DesperationTween.stop_all()
		$DesperationTween.remove_all()
	if force or not $DesperationTween.is_active():
		$DesperationTween.interpolate_property($DesperationLayer1, "volume_db", $DesperationLayer1.volume_db, -60, 2.0)
		$DesperationTween.interpolate_property($DesperationLayer2, "volume_db", $DesperationLayer2.volume_db, -60, 2.0)
		$DesperationTween.start()
