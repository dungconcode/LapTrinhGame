extends Node

func init():
	Data.apply("prestige.score", 0)
	
	match Level.loadout.modeConfig.get(CONST.MODE_CONFIG_PRESTIGE_VARIANT):
		CONST.MODE_PRESTIGE_MINER:
			Data.apply("prestige.baseperwave", 1)
			Data.apply("prestige.multiplier", 1)
			Data.listen(self, "event.keepers.insidedome")
		CONST.MODE_PRESTIGE_COUNTDOWN:
			Data.apply("prestige.baseperwave", 1)
			Data.apply("prestige.multiplier", 20)
		CONST.MODE_PRESTIGE_PROVOCATION:
			Data.apply("prestige.baseperwave", 100)
			Data.apply("prestige.multiplier", 5)
		CONST.MODE_PRESTIGE_ENDLESS:
			Data.apply("prestige.baseperwave", 1)
			Data.apply("prestige.multiplier", 1)
			Achievements.addIfOpen(self, "PRESTIGE_MULTIPLIER")

	Data.listen(self, "monsters.cycle")
	Data.listen(self, "dome.health")
	Data.listen(self, "upgrade.gameover")
	
	Achievements.addIfOpen(self, "PRESTIGE_CHUNK")
	Achievements.addIfOpen(self, "PRESTIGE_WIN")
	
	Level.world.addBackgroundHub(preload("res://content/gamemode/prestige/rocket/RocketHub.tscn").instantiate())
	
	CheatDetection.start()

func afterInitialized():
	if not GameWorld.devMode:
		var enabledIllegalMods := get_enabled_mods_not_allowed_in_prestige()
		if enabledIllegalMods.size() > 0:
			$ScriptTween.interpolate_callback(StageManager, 0.5, "startStage", "stages/error/error")
			$ScriptTween.start()
	
	if SaveGame.currentLoadingSavegame:
		await GameWorld.savegame_loaded
		var freeCycles = 2 + round(sqrt(int(Data.of("monsters.cycle"))))
		var overshoot = 0.02 * clamp(GameWorld.loadCount - freeCycles, 0, 20)
		Data.apply("monstermodifiers.totalrunweightmodifier", 1.0 + overshoot)
		Data.apply("monstermodifiers.damage", 1.0 + overshoot)
	
func propertyChanged(property:String, oldValue, newValue):
	match property:
		"event.keepers.insidedome":
			if Keepers.oneInsideMine():
				GameWorld.runStarted = true
				Data.apply("wavemeter.showbar", true)
				Data.unlisten(self, "event.keepers.insidedome")
		"upgrade.gameover":
#			not in the deployment right now, but great!
#			Level.stage.leavePlanet()
			for keeper in Keepers.getAll():
				keeper.exitStation()
			Level.stage.stopKeeperInput()
			Level.moveHudOut()
			GameWorld.handleGameWon({"prestigeScore": Data.of("prestige.score")})
			Level.monsters.disabled = true
			Data.unlisten(self, "dome.health")
			
			if Data.of("monsters.wavepresent"):
				Data.apply("monsters.wavepresent", false)
			
			for m in get_tree().get_nodes_in_group("monster"):
				m.onGameLost()
			
			Audio.stopBattleMusic()
			await get_tree().create_timer(0.2).timeout
			Audio.startEnding()
			await get_tree().create_timer(4.0).timeout
			# use six when using "leavePlanet"
#			yield(get_tree().create_timer(6.0), "timeout")
			
			var popup = preload("res://content/gamemode/prestige/RunFinishedPopup.tscn").instantiate()
			Level.stage.showEndingPanel(popup)
		"monsters.cycle":
			var multiplier = Data.of("prestige.multiplier")
			var base = Data.of("prestige.baseperwave")
			var change = max(0, int(base) * int(multiplier))
			var newScore = change + int(Data.of("prestige.score"))
			if SaveGame.currentLoadingSavegame:
				return
			CheatDetection.registerPrestige(base, multiplier, newScore)
			match Level.loadout.modeConfig.get(CONST.MODE_CONFIG_PRESTIGE_VARIANT, ""):
				CONST.MODE_PRESTIGE_PROVOCATION:
					if multiplier == 0:
						Data.apply("prestige.score", newScore * 2) # double if made it here alive
						Level.stage.stopKeeperInput()
						Audio.startEnding()
						
						await get_tree().create_timer(3.0).timeout
						GameWorld.handleGameWon({"prestigeScore": newScore})
						var popup = preload("res://content/gamemode/prestige/RunFinishedPopup.tscn").instantiate()
						Level.stage.showEndingPanel(popup)
					else:
						Data.apply("prestige.score", newScore)
						Data.apply("prestige.multiplier", multiplier - 1)
				CONST.MODE_PRESTIGE_COUNTDOWN:
					if newValue == 20:
						Data.apply("prestige.score", newScore * 2) # double if made it here alive
						Level.stage.stopKeeperInput()
						Audio.startEnding()
						
						await get_tree().create_timer(3.0).timeout
						GameWorld.handleGameWon({"prestigeScore": newScore})
						var popup = preload("res://content/gamemode/prestige/RunFinishedPopup.tscn").instantiate()
						Level.stage.showEndingPanel(popup)
					else:
						Data.apply("prestige.score", newScore)
						Data.apply("prestige.multiplier", multiplier - 1)
				CONST.MODE_PRESTIGE_MINER:
					Data.apply("prestige.score", newScore)
					if newValue == 20:
						Level.stage.stopKeeperInput()
						Audio.startEnding()
						
						await get_tree().create_timer(3.0).timeout
						GameWorld.handleGameWon({"prestigeScore": newScore})
						var popup = preload("res://content/gamemode/prestige/RunFinishedPopup.tscn").instantiate()
						Level.stage.showEndingPanel(popup)
				_:
					Data.apply("prestige.score", newScore)
					
		"dome.health":
			if newValue <= 0 and not GameWorld.lost:
				Level.moveHudOut()
				GameWorld.lost = true
				Data.apply("monsters.wavepresent", false)
				
				var delay = Level.stage.playGameLostAnimation()
				await get_tree().create_timer(delay).timeout
				Audio.sound("lose")
				await get_tree().create_timer(0.2).timeout
				GameWorld.handleGameLost({"prestigeScore": Data.of("prestige.score")})
				
				Audio.startGameOver(1.0)
				await get_tree().create_timer(5.0).timeout
				
				var popup = preload("res://content/gamemode/prestige/RunFinishedPopup.tscn").instantiate()
				Level.stage.showEndingPanel(popup)

func addCycleData(data:Dictionary):
	data["prestige.multiplier"] = Data.ofOr("prestige.multiplier", 0)
	data["prestige.baseperwave"] = Data.ofOr("prestige.baseperwave", 0)
	data["prestige.score"] = Data.ofOr("prestige.score", 0)

func getRunWeight() -> float:
	match Level.loadout.modeConfig.get(CONST.MODE_CONFIG_PRESTIGE_VARIANT, ""):
		CONST.MODE_PRESTIGE_MINER:
			return 0.0
	
	var weight := 0.0
	var cycle = Data.of("monsters.cycle")
	
	weight += round(pow(2, ((cycle - (1 + Level.loadout.difficulty)) * 0.08)) * cycle * 10 + cycle * 10)
	weight += GameWorld.additionalRunWeight
	weight += Data.of("prestige.provokedwavestrengthadditive")
	weight *= Data.of("prestige.provokedwavestrength")
	weight *= Data.of("monstermodifiers.totalrunweightmodifier")
	weight *= 1.0 + Level.loadout.difficulty * 0.1
	
	return max(15, weight)

static func get_enabled_mods_not_allowed_in_prestige() -> Array:
	var enabledIllegalMods := []
	var ml = ModLoaderUserProfile.get_current().mod_list
	for modId in ml:
		if not ModLoaderStore.mod_data.has(modId):
			continue
		if not CONST.PRESTIGE_WHITELIST_MOD_IDS.has(modId) and ml[modId].is_active:
			enabledIllegalMods.append(modId)
	return enabledIllegalMods
