extends Node2D

class_name Monsters

var spawnPunishers:bool
var disabled := false
var waveTime := 0.0
var softRestartWave := 0.0
var monsterIndex := 0
var battleIntensity := 0.0
var battleIntensityStallThreshold := 0.0
var timeBattleStalled := 0.0
var keeperInDomeDuringWave := false
var finale := false
var forceCountdown := false
var forceCountdownWavePunishment := false
var spawnEscalation := 0
var monstersInWave := []
var currentWave:Wave
var spawnPlan:Array
var monsterCount := 0

var waveDamageCounter := 0.0 
var lastWaveStrengthModChange := 0.0 

# spawn
var nextWaveType := 1

var waveCounter:int
var remainingMonsters:int

func init():
	spawnPunishers = Data.ofOr("monstermodifiers.punishers", true)
	disabled = GameWorld.devMode
	applyTimeBetweenWaves()
	Data.apply("monsters.wavepresent", false)
	
	Data.listen(self, "map.tilesdestroyed")
	Data.listen(self, "dome.health")
	Data.listen(self, "inventory.iron")
	Data.listen(self, "shield.health")
	Data.listen(self, "event.keepers.insidestation")

func _ready():
	#hack: you can save and quit before leaving the battle station making the monsters.wavebattle 
	#be stuck in true, this ensures the property is updated after loading
	create_tween().tween_callback(updateWaveBattleEnded).set_delay(0.1)

func updateWaveBattleEnded():
	var wave =  Data.of("monsters.wavebattle")
	var present =  Data.of("monsters.wavepresent")
	if wave and not present:
		# resume regular clock only after a keeper exited the station
		Data.apply("monsters.wavebattle", false)

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"map.tilesdestroyed":
			if newValue >= 8:
				GameWorld.runStarted = true
				Data.unlisten(self, "map.tilesdestroyed")
		"dome.health":
			if newValue < oldValue:
				waveDamageCounter += oldValue - newValue
		"inventory.iron":
			# if waves are not already coming, start the spawning now
			if not GameWorld.runStarted:
				GameWorld.runStarted = true
				Data.unlisten(self, "inventory.iron")
		"shield.health":
			var amount = newValue - oldValue
			if amount < 0:
				waveDamageCounter += amount * 0.33

func _process(delta):
	if Options.visibleMonsters:
		for m in get_tree().get_nodes_in_group("monster"):
			m.aim(true)
	
	if disabled or GameWorld.paused or not GameWorld.runStarted or GameWorld.lost or GameWorld.won:
		return
	
	var waveBattle =  Data.of("monsters.wavebattle")
	var wavePresent =  Data.of("monsters.wavepresent")
	var allInsideStation = Keepers.allInsideStation()
	if waveBattle and not wavePresent:
		if allInsideStation:
			softRestartWave -= delta
			if softRestartWave <= 0.0:
				Data.apply("monsters.wavebattle", false)
		else:
			# resume regular clock only after a keeper exited the station
			Data.apply("monsters.wavebattle", false)
	
	if forceCountdown:
		var coolodown = Data.of("monsters.waveCooldown")
		if coolodown <= 0.0:
			spawnWave()
		elif coolodown <= GameWorld.getTimeBetweenWaves() * 0.7 and not forceCountdownWavePunishment:
			forceCountdownWavePunishment = true
			Data.changeByInt("monsters.additionalwaveweight", 40 + ceil(0.2 * Level.mode.getRunWeight()))
	
	var atLeastOneKeeperIsInsideDome = Keepers.oneInsideDome()
	if wavePresent:
		keeperInDomeDuringWave = keeperInDomeDuringWave or atLeastOneKeeperIsInsideDome
		var gracePeriodOver = waveTime > 10.0 - Level.loadout.difficulty * 2.0
		var maxMonsters = max(2, 2 + Level.loadout.difficulty)
		var headCount = getCurrentHeadCount()
		var waveStartedFully = keeperInDomeDuringWave or gracePeriodOver
		var belowMinimalMonsterCount = headCount < max(2, 2 + Level.loadout.difficulty)
		var doSpawn = (waveStartedFully or belowMinimalMonsterCount) and headCount <= currentWave.maxMonsters
		waveTime += delta
		
		if doSpawn:
			if spawnPlan.size() > monsterIndex + 1:
				var nextMonsterPlan = spawnPlan[monsterIndex+1]
				if waveTime > nextMonsterPlan.time:
					monsterIndex += 1
					_spawnMonster(nextMonsterPlan.breed, nextMonsterPlan.variant)
			elif monstersInWave.size() == 0 and not $SpawnTween.is_active() and get_tree().get_nodes_in_group("projectile").size() == 0:
				finishWave()
				return
		
		if waveStartedFully and waveTime >= 10.0:
			if forceCountdown and timeBattleStalled >= 30 + spawnEscalation * 20:
				var monsters:Array
				match spawnEscalation:
					0: monsters = ["walker", "flyer", "stingray", "rockman"]
					1: monsters = ["mucker", "hornet", "worm", "tick"]
					2: monsters = ["diver", "bolter", "shifter", "tick"]
					_: monsters = ["phaser", "breeder", "beast"]
				for _i in 2 + spawnEscalation:
					_spawnMonster(monsters.pick_random(), ["left", "right"].pick_random())
				spawnEscalation += 1
				GameWorld.incrementRunStat("spawn_escalation")
			
			var atLeastOneHittable = false
			for m in monstersInWave:
				if m.alive() and not m.invulnerable and m.canBeHit():
					atLeastOneHittable = true
					break
			
			if atLeastOneHittable:
				battleIntensity = battleIntensity * (1.0 - delta * 0.5) - delta
			
			if battleIntensity <= battleIntensityStallThreshold and atLeastOneHittable:
				if atLeastOneHittable:
					timeBattleStalled += delta
			elif battleIntensity >= 2 * battleIntensityStallThreshold:
				timeBattleStalled = max(0.0, timeBattleStalled - delta)
		
		#prints("timeBattleStalled", timeBattleStalled, "   battleIntensity", battleIntensity, "  battleIntensityStallThreshold", battleIntensityStallThreshold)
		
		if forceCountdown:
			doWaveCountdown(delta)
		else:
			if timeBattleStalled >= 12.0 and Data.ofOr("monsters.antistall", true):
				applyTimeBetweenWaves()
				countWaveUp()
				forceCountdown = true
				battleIntensityStallThreshold = 50
				GameWorld.incrementRunStat("waves_stalled")
	elif not waveBattle:
		if Data.of("monsters.wavedelay") > 0.0:
			Data.changeByInt("monsters.wavedelay", -delta * GameWorld.cycleSpeed)
		else:
			doWaveCountdown(delta)
		
		if Data.of("monsters.waveCooldown") <= 0.0:
			spawnWave()

func doWaveCountdown(delta:float):
	var wcd = Data.of("monsters.wavecooldown")
	wcd -= delta * GameWorld.cycleSpeed
	if wcd < 10.0 and Keepers.allInsideStation():
		# tick down faster when waiting for the wave
		wcd -= delta * 1.0
	Data.apply("monsters.waveCooldown", wcd)

func getCurrentHeadCount() -> float:
	var count := 0.0
	for m in get_tree().get_nodes_in_group("monster"):
		count += m.headCount
	return count

func applyTimeBetweenWaves(applyOnlyIfCooldownIsZero := false):
	if not applyOnlyIfCooldownIsZero or Data.of("monsters.waveCooldown") <= 0.0:
		var tbw = GameWorld.getTimeBetweenWaves()
		Data.apply("monsters.timeBetweenWaves", tbw)
		Data.apply("monsters.waveCooldown", tbw)

func serialize()->Dictionary:
	var data := {
		"disabled": disabled,
		"waveTime": waveTime,
		"waveCooldown": Data.of("monsters.waveCooldown"),
		"wavepresent": Data.of("monsters.wavepresent"),
		"spawnPlan": var_to_str(spawnPlan),
		"monsterIndex": monsterIndex,
		"lastMonsters": var_to_str($WaveGenerator.lastMonsters)
	}
	return data

func deserialize(data:Dictionary):
	for m in monstersInWave:
		if is_instance_valid(m):
			m.free()
	monstersInWave.clear()
	
	await GameWorld.savegame_loaded
	
	disabled = data["disabled"]
	waveTime = data["waveTime"]
	spawnPlan = BackwardCompatibilityUtils.str_to_var(data["spawnPlan"])
	monsterIndex = data["monsterIndex"]
	if data.has("lastMonsters"):
		$WaveGenerator.lastMonsters = BackwardCompatibilityUtils.str_to_var(data["lastMonsters"])
	Data.apply("monsters.waveCooldown", data["waveCooldown"])
	Data.apply("monsters.wavepresent", data["wavepresent"])
	
func spawnWave():
	var currentRunWeight = Level.mode.getRunWeight()
	if currentRunWeight <= 0.0:
		finishWave()
		return
	
	if not Data.of("monsters.wavepresent"):
		SaveGame.saveGame(0)
		GameWorld.removeAvailableUpgradeLimit("between_waves")
	
	waveTime = -2.0
	monsterIndex = -1
	Data.apply("monsters.wavepresent", true)
	Data.apply("monsters.wavebattle", true)
	keeperInDomeDuringWave = false
	forceCountdown = false
	waveDamageCounter = 0
	battleIntensity = 0.0
	GameWorld.incrementRunStat("wave_stall_time", timeBattleStalled)
	timeBattleStalled = 0
	spawnEscalation = 0
	battleIntensityStallThreshold = 20
	
	var minimumTimeBetweenMonsters:float
	if Data.has("monsters.minimumtimebetweenmonsters"):
		minimumTimeBetweenMonsters = Data.of("monsters.minimumtimebetweenmonsters")
	else:
		match Level.loadout.difficulty:
			-2: minimumTimeBetweenMonsters = 0.5
			-1: minimumTimeBetweenMonsters = 0.3
			0: minimumTimeBetweenMonsters = 0.17
			2: minimumTimeBetweenMonsters = 0.08
	
	var divisor = 2.6 - Level.loadout.difficulty * 0.1
	var runWeightProgression = 1.0 - ((log(currentRunWeight) / log(10)) - 1.17) / divisor
	Data.apply("monsters.timingmod", clamp(runWeightProgression, minimumTimeBetweenMonsters, 1.0))
	currentWave = $WaveGenerator.generateWave(currentRunWeight, GameWorld.waveStrengthModifier)
	spawnPlan = currentWave.generateSpawnPlan()
	
	var w = {
		"waveIndex": Data.of("monsters.cycle"), 
		"currentRunWeight": currentRunWeight,  
		"waveStrengthModifier": GameWorld.waveStrengthModifier,
		"wave": currentWave.entries,
		}
	Backend.event("wave_started", w)

func countWaveUp():
	var cycles = Data.of("monsters.cycle") + 1
	Data.apply("monsters.cycle", cycles)
	Data.apply("monsters.additionalcycletime", 15 * pow(cycles, 0.7) - (14 + cycles * 2))
	waveCounter += 1
	forceCountdownWavePunishment = false

func finishWave():
	applyTimeBetweenWaves(true)
	Data.apply("monsters.wavepresent", false)
	$WaveGenerator.waveFinished(currentWave)

	if Data.of("monsters.wavebattle") and not Keepers.allInsideStation():
		# only needed when keepers already exited before battle was over, which can happen with battle gadgets
		Data.apply("monsters.wavebattle", false)
	
	GameWorld.incrementRunStat("waves_survived")
	
	if not forceCountdown:
		countWaveUp()
	softRestartWave = 5.0
	forceCountdown = false
	
#	print("damage: "+str(waveDamageCounter))
	if Level.loadout.modeId == CONST.MODE_RELICHUNT: 
		var mod:= 1.0
		var damageConsideredBad = 200
		var damageConsideredGood = 80 
#		var damageConsideredGood = min(50 + cycles * 4, 200) 
		if waveDamageCounter > damageConsideredBad:
			mod = -0.6 * ((waveDamageCounter - damageConsideredBad) / (damageConsideredBad * 3.0))
#			print("it was a bad round, mod changes by "+str(mod))
		elif waveDamageCounter < damageConsideredGood:
			mod = 0.05 + (1.0 - (waveDamageCounter / damageConsideredGood)) * 0.1
#			print("it was a good round, mod changes by "+str(mod))
		else:
			mod = (1.0 - GameWorld.waveStrengthModifier) * 0.5
#			print("it was an average round, normalize by "+str(mod))
		lastWaveStrengthModChange = mod
		GameWorld.waveStrengthModifier = clamp(GameWorld.waveStrengthModifier + mod, 0.7 - Level.loadout.difficulty * 0.1, 1.3 + Level.loadout.difficulty * 0.1)
#		print("new wave modifier: "+str(GameWorld.waveStrengthModifier))
	
	SaveGame.saveGame(0)
	currentWave = null
	GameWorld.setUpgradeLimitAvailable("between_waves")
	
	Backend.event("wave_finished", {
		"waveIndex": Data.of("monsters.cycle"), 
		"waveDamageCounter": waveDamageCounter, 
		"trackedDamageDealt": GameWorld.trackedDamageDealt, 
		"trackedDamageReceived": GameWorld.trackedDamageReceived, 
		})

func _spawnMonster(breed:String, variant:String, groupSize := 1):
	var monster
	match breed:
		"walker":
			monster = preload("res://content/monster/walker/Walker.tscn").instantiate()
			monster.path = Level.world.assignRandomPath(Data.of(breed+".movetype"), variant, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
		"flyer": 
			monster = preload("res://content/monster/flyer/Flyer.tscn").instantiate()
			monster.setProviders(Level.world.getFlyerPathProvider(), Level.dome.getProjectileTargetProvider(), variant)
		"stingray": 
			monster = preload("res://content/monster/stingray/Stingray.tscn").instantiate()
			monster.setProviders(Level.world.getFlyerPathProvider(), Level.dome.getProjectileTargetProvider(), variant)
		"driller": 
			monster = preload("res://content/monster/driller/Driller.tscn").instantiate()
			monster.path = Level.world.assignRandomPath(Data.of(breed+".movetype"), variant, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
		"diver": 
			monster = preload("res://content/monster/diver/Diver.tscn").instantiate()
			var pp = Level.dome.PiercePoints
			monster.domeTarget = pp.get_node("Left").global_position if variant == CONST.LEFT else pp.get_node("Right").global_position
			monster.retreatPosition = $DiverPaths/RetreatLeft if variant == CONST.LEFT else $DiverPaths/RetreatRight
			var path:Path2D = $DiverPaths/StartLeft if variant == CONST.LEFT else $DiverPaths/StartRight
			monster.divePosition = path.curve.sample_baked(path.curve.get_baked_length()*randf())
		"tick":
			var amount:int = Data.of("tick.groupsize") + round(randf()*Data.of("tick.grouprandom"))
			var time := 0.0
			var interspawntime = Data.of("tick.interspawntime")
			for _i in range(0,amount):
				$SpawnTween.interpolate_callback(self, time, "_spawnMonster", "tick_single", variant, amount)
				time += interspawntime + randf() * interspawntime
			# so spawn is mostly complete first
			waveTime -= time * 0.75
			$SpawnTween.start()
			return
		"tick_single":
			monster = preload("res://content/monster/tick/Tick.tscn").instantiate()
			monster.headCount = 1.0 / float(groupSize)
			monster.path = Level.world.assignRandomPath(Data.of("tick.movetype"), variant, monster)
			monster.target = Level.dome.getFrontAttackPosition(variant)
		"bigtick":
			var amount:int = Data.of("bigtick.groupsize") + round(randf()*Data.of("bigtick.grouprandom"))
			var time := 0.0
			var interspawntime = Data.of("bigtick.interspawntime")
			for _i in range(0,amount):
				$SpawnTween.interpolate_callback(self, time, "_spawnMonster", "bigtick_single", variant, amount)
				time += interspawntime + randf() * interspawntime
			# so spawn is mostly complete first
			waveTime -= time * 0.75
			$SpawnTween.start()
			return
		"bigtick_single":
			monster = preload("res://content/monster/bigtick/Bigticker.tscn").instantiate()
			monster.headCount = 1.0 / float(groupSize)
			monster.path = Level.world.assignRandomPath(Data.of("bigtick.movetype"), variant, monster)
			monster.target = Level.dome.getFrontAttackPosition(variant)
		"worm":
			monster = preload("res://content/monster/worm/Worm.tscn").instantiate()
			monster.path = Level.world.assignRandomPath(Data.of(breed+".movetype"), variant, monster)
			monster.projetileTargetProvider = Level.dome.getProjectileTargetProvider()
		"bolter":
			monster = preload("res://content/monster/bolter/Bolter.tscn").instantiate()
			monster.setProviders(Level.world.getFlyerPathProvider(), Level.dome.getProjectileTargetProvider(), variant)
		"mucker":
			monster = preload("res://content/monster/mucker/Mucker.tscn").instantiate()
			monster.path = Level.world.assignRandomPath(Data.of(breed+".movetype"), variant, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
		"shifter":
			monster = preload("res://content/monster/shifter/Shifter.tscn").instantiate()
			monster.setProviders(Level.world.getFlyerPathProvider(), Level.dome.getProjectileTargetProvider(), variant)
		"butterfly": 
			monster = preload("res://content/monster/butterfly/Butterfly.tscn").instantiate()
			monster.setProviders(Level.world.getFlyerPathProvider(), Level.dome.getProjectileTargetProvider(), variant)
		"beast":
			monster = preload("res://content/monster/Beast/Beast.tscn").instantiate()
			monster.path = Level.world.assignRandomPath(Data.of(breed+".movetype"), variant, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(Data.of(breed+".meleetarget"))
		"rockman":
			monster = preload("res://content/monster/rockman/Rockman.tscn").instantiate()
			monster.path = Level.world.assignRandomPath(Data.of(breed+".movetype"), variant, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
		"scarab":
			monster = preload("res://content/monster/scarab/Scarab.tscn").instantiate()
			monster.setProviders(Level.world.getFlyerPathProvider(), Level.dome.getProjectileTargetProvider(), variant)
		"stag":
			monster = preload("res://content/monster/stag/Stag.tscn").instantiate()
			monster.path = Level.world.assignRandomPath(Data.of(breed+".movetype"), variant, monster)
			monster.projectileTargetProvider = Level.dome.getProjectileTargetProvider()
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
		"hornet":
			monster = preload("res://content/monster/hornet/Hornet.tscn").instantiate()
			monster.setProviders(Level.world.getFlyerPathProvider(), Level.dome.getMeleeTarget(variant), variant)
		"breeder":
			monster = preload("res://content/monster/breeder/Breeder.tscn").instantiate()
			monster.path = Level.world.assignRandomPath(Data.of(breed+".movetype"), variant, monster)
		"tormentor":
			monster = preload("res://content/monster/tormentor/Tormentor.tscn").instantiate()
			monster.path = Level.world.assignRandomPath(Data.of(breed+".movetype"), variant, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
		"phaser":
			monster = preload("res://content/monster/phaser/Phaser.tscn").instantiate()
			monster.nextSide = variant
			monster.path = Level.world.assignRandomPath(Data.of(breed+".movetype"), variant, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
		"bloater":
			monster = preload("res://content/monster/bloater/Bloater.tscn").instantiate()
			monster.setProviders(Level.world.getFlyerPathProvider(), variant)
			monster.projectileTargetProvider = Level.dome.getProjectileTargetProvider()
		"burrower":
			monster = preload("res://content/monster/burrower/Burrower.tscn").instantiate()
			monster.path = Level.world.assignRandomPath(Data.of("burrower.movetype"), variant, monster)
		_:
			Logger.error("cannot spawn unknown breed", "Monsters._spawnMonster", breed)
			return
	
	remainingMonsters += 1
	monsterCount += 1
	monster.inOriginalSpawnPlan = true
	monster.counter = monsterCount
	monster.connect("died", Callable(self, "monsterDied").bind(monster))
	
	Level.viewports.addMonster(monster)
	monstersInWave.append(monster)

func registerMonster(monster):
	remainingMonsters += 1
	monsterCount += 1
	monster.counter = monsterCount
	monster.connect("died", Callable(self, "monsterDied").bind(monster))
	Level.viewports.addMonster(monster)
	monstersInWave.append(monster)

func monsterDied(m):
	monstersInWave.erase(m)
	remainingMonsters -= 1
	
	if m.inOriginalSpawnPlan:
		battleIntensity += 10 * m.headCount
	
	#count monster kills in finale, but not the ones killed by the relic (disabled is set upon loosing)
	if not (finale and disabled):
		GameWorld.incrementRunStat("monsters_killed", m.headCount)
		Recorder.recordMonsterKilled(m.techId)

func instantlyKillWave():
	$SpawnTween.remove_all()
	for m in get_tree().get_nodes_in_group("monster"):
		m.died.emit()
		m.queue_free()
	if Data.of("monsters.wavepresent"):
		remainingMonsters = 0
		finishWave()

func onGameLost():
	disabled = true
	$SpawnTween.remove_all()

func startFinalAct():
	finale = true
	if Data.of("monsters.wavepresent"):
		# fix current wave
		currentWave = null
		spawnPlan.clear()
	waveTime = -4.0
	monsterIndex = -1
	Data.apply("monsters.timingmod", Data.of("monsters.timingmod") * 0.8)
	Data.apply("monsters.wavepresent", true)
	Data.apply("monsters.wavebattle", true)
	Data.apply("monsters.waveCooldown", 0)
	Data.apply("monsters.wavedelay", 0)
	
	var fixedStrength = Data.ofOr("monsters.finalwavefixedstrength", 0)
	var mod = Data.ofOr("monstermodifiers.finalwavemultiplicator", 4.5)
	var finalWaveStrength = fixedStrength if fixedStrength > 0 else max(800, Level.mode.getRunWeight() * mod)
	currentWave = $WaveGenerator.generateWave(finalWaveStrength, 1.0)
	spawnPlan = currentWave.generateSpawnPlan()

func pauseChanged():
	if GameWorld.paused:
		$SpawnTween.stop_all()
	else:
		$SpawnTween.resume_all()

func monsterLostHealth(damageTaken):
	battleIntensity += damageTaken

func domeLostHealth(damageTaken):
	battleIntensity += damageTaken
