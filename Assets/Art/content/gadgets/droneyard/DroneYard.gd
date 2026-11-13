extends "res://content/gadgets/PrimaryGadget.gd"

enum BATTLE_ABILITIES {NOTHING, BATTLEGRID, PARASITES}

var droneCurve:Curve2D
var targetsByDrones := {}
var dronesByTarget := {}
var cooldown := 0.0
var spawningGridDrones := false

var battle_ability

func _ready():
	Data.listen(self, "droneyard.dronespeed", true)
	Data.listen(self, "droneyard.overcharged", true)
	Data.listen(self, "droneyard.battleability", true)
	Data.listen(self, "monsters.wavepresent")
	Data.listen(self, "droneyard.battleabilityuses")
	
	if not SaveGame.currentLoadingSavegame:
		Data.apply("droneyard.overcharged", false)
		Data.apply("droneyard.remainingbattleabilityuses", 0)
	
	$GridDroneNestBack.visible = false
	$GridDroneNestFront.visible = false
	$ParasiteDroneNestBack.visible = false
	$ParasiteDroneNestFront.visible = false
	
	match domeId:
		"dome1":
			$Sprite.frame_coords.y = 0
			$Sprite.position.x = -4
			$Sprite.position.y = -19
		"dome2":
			$Sprite.frame_coords.y = 1
		"dome3":
			$Sprite.frame_coords.y = 2
		"dome4":
			$Sprite.frame_coords.y = 3
	
	match $Sprite.frame:
		0: $OverchargeSprite.position = Vector2(-4, -16)
		1: $OverchargeSprite.position = Vector2(-3, -19)
		2: $OverchargeSprite.position = Vector2(-2, -30)
		3: $OverchargeSprite.position = Vector2(-2, -23)
		4: $OverchargeSprite.position = Vector2(-4, -26)
		5: $OverchargeSprite.position = Vector2(-2, -35)
		6: $OverchargeSprite.position = Vector2(-4, -17)
		7: $OverchargeSprite.position = Vector2(-6, -20)
		8: $OverchargeSprite.position = Vector2(-5, -27)
		9: $OverchargeSprite.position = Vector2(-2, -22)
		10: $OverchargeSprite.position = Vector2(-3, -29)
		11: $OverchargeSprite.position = Vector2(0, -39)
	
	Style.init(self)
	
	Level.addTutorial(self, "overcharge")
	
	#stop droneyard from spawning new transport drones before we finish loading
	if SaveGame.currentLoadingSavegame:
		await GameWorld.savegame_loaded 
	Data.listen(self, "droneyard.transportdronecount", true)

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"droneyard.dronespeed":
			$DroneDispatcher.setBaseSpeed(newValue)
		"droneyard.transportdronecount":
			$DroneDispatcher.setAmount(newValue)
			if newValue >= 3:
				$Sprite.frame_coords.x = 2
			elif newValue >= 2:
				$Sprite.frame_coords.x = 1
			else:
				$Sprite.frame_coords.x = 0
		"monsters.wavepresent":
			if newValue:
				var ability = Data.of("droneyard.battleability") as BATTLE_ABILITIES
				match ability:
					BATTLE_ABILITIES.BATTLEGRID:
						spawningGridDrones = true
						Data.apply("droneyard.remainingbattledronecount", getSpawnCount())
					BATTLE_ABILITIES.PARASITES:
						var uses = Data.of("droneyard.battleabilityuses")
						Data.apply("droneyard.remainingbattleabilityuses", uses)
				
			else:
				var ability = Data.of("droneyard.battleability") as BATTLE_ABILITIES
				match ability:
					BATTLE_ABILITIES.BATTLEGRID:
						$GridDroneNestBack.speed_scale = 1.0
						$GridDroneNestFront.speed_scale = 1.0
						spawningGridDrones = false
					BATTLE_ABILITIES.PARASITES:
						Data.apply("droneyard.remainingbattleabilityuses", 0)
				cooldown = 0
				removeDrones()
				if not SaveGame.currentLoadingSavegame:
					Data.apply("droneyard.overcharged", false)
			targetsByDrones.clear()
			dronesByTarget.clear()
		"droneyard.battleability":
			battle_ability = newValue as BATTLE_ABILITIES
			match battle_ability:
				BATTLE_ABILITIES.PARASITES:
					add_to_group("dome_ability1")
					droneCurve = $ParasiteDronePath.curve
					$ParasiteDroneNestBack.visible = true
					$ParasiteDroneNestFront.visible = true
				BATTLE_ABILITIES.BATTLEGRID:
					droneCurve = $BattleDronePath.curve
					$GridDroneNestBack.visible = true
					$GridDroneNestBack.play("idle")
					$GridDroneNestFront.visible = false
					if (not oldValue or oldValue == 0) and Data.of("monsters.wavepresent"):
						spawningGridDrones = true
						Data.apply("droneyard.remainingbattledronecount", getSpawnCount())
		"droneyard.battleabilityuses":
			if oldValue != null:
				var delta = newValue - oldValue
				if delta > 0 and Data.of("monsters.wavepresent"):
					Data.changeByInt("droneyard.remainingbattleabilityuses", delta)
		"droneyard.overcharged":
			if newValue:
				$OverchargeSprite.play("active")
			else:
				$OverchargeSprite.play("inactive")

func _process(delta):
	if GameWorld.paused:
		return
	
	match battle_ability:
		BATTLE_ABILITIES.BATTLEGRID:
			if spawningGridDrones:
				if cooldown > 0.0:
					cooldown -= delta
					return
				
				if $GridDroneNestBack.animation == "idle":
					$GridDroneNestFront.visible = true
					$GridDroneNestFront.play("spawn_front")
					$GridDroneNestBack.play("spawn_back")
					cooldown = Data.of("droneyard.battledronespawntime")
					
					#if the cooldown is lower than the animation time, we have to play at double speed
					if cooldown < 2.0:
						$GridDroneNestBack.speed_scale = 2.0
						$GridDroneNestFront.speed_scale = 2.0
					
		BATTLE_ABILITIES.PARASITES:
			if cooldown > 0.0:
				cooldown -= delta
				return
		
			for drone in get_tree().get_nodes_in_group("battle_drones"):
				if drone.canTakeTarget() and not targetsByDrones.has(drone):
					var monsters = get_tree().get_nodes_in_group("monster")
					var bestMonster = null
					for m in monsters:
						if not dronesByTarget.has(m) and m.alive() and m.canBeHit():
							if not bestMonster or (5 * bestMonster.currentHealth + bestMonster.maxHealth) < (5 * m.currentHealth + m.maxHealth):
								bestMonster = m
					
					if bestMonster:
						drone.assignTarget(bestMonster)
						targetsByDrones[drone] = bestMonster
						dronesByTarget[bestMonster] = drone
						bestMonster.connect("died", Callable(self, "monsterDied").bind(bestMonster))
					
					cooldown = randf_range(0.4, 0.8)
					return

func monsterDied(m):
	var drone = dronesByTarget[m]
	drone.targetDied()
	targetsByDrones.erase(drone)
	dronesByTarget.erase(m)

func spawnGridDrone():
	$ReleaseDroneSound.play()
	var drone = preload("res://content/gadgets/droneyard/BattleDrone.tscn").instantiate()
	drone.position = $BattleDroneSpawnPoint.global_position
	if Data.of("droneyard.overcharged"):
		var droneBuff = Data.of("droneyard.overchargebattledronestrength")
		drone.setBuff(droneBuff)
	Level.viewports.addElement(drone)
	updateGridDronePositions()
	
	var remaining = Data.ofOr("droneyard.remainingbattledronecount", 0)
	if remaining <= 1:
		spawningGridDrones = false
	Data.apply("droneyard.remainingbattledronecount", remaining - 1)

func getSpawnCount(subtractExistingDrones := true) -> int:
	var overcharged = Data.of("droneyard.overcharged")
	var count = Data.of("droneyard.battledronecount")
	if overcharged:
		count += ceil(count * Data.of("droneyard.overchargebattledronecount"))
	if subtractExistingDrones:
		count -= get_tree().get_nodes_in_group("battle_drones").size()
	return count

func spawnParasiteDrones():
	$ReleaseParasiteDroneSound.play()
	var droneBuff:float
	if Data.of("droneyard.overcharged"):
		droneBuff = Data.of("droneyard.overchargebattledronestrength")
	for i in getSpawnCount(false):
		var drone = preload("res://content/gadgets/droneyard/ParasiteDrone.tscn").instantiate()
		drone.position = $BattleDroneSpawnPoint.global_position
		drone.buff = droneBuff
		drone.setCurve($ParasiteDronePath.curve)
		Level.viewports.addElement(drone)

func removeDrones():
	var drones = get_tree().get_nodes_in_group("battle_drones")
	if drones.size() > 0:
		var t = create_tween()
		t.set_parallel(true)
		for drone in drones:
			t.tween_callback(drone.returToOrigin).set_delay(randf_range(0, 1.0))

func canOvercharge() -> bool:
	return not Data.of("droneyard.overcharged") and Data.of("droneyard.overchargebattledronecount") > 0.0

func overcharge():
	$OverchargeSound.play()
	Data.apply("droneyard.overcharged", true)
	Data.changeByInt("inventory.water", -1)
	Backend.event("gadget_overcharged", {"gadget": "droneyard"})

func canFocusUse(keeper:Keeper) -> bool:
	return canOvercharge()

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	return tryOvercharge()

func updateGridDronePositions():
	var drones = get_tree().get_nodes_in_group("battle_drones")
	if drones.is_empty() or not droneCurve:
		return
	
	var curveLength:float = droneCurve.get_baked_length()
	var step: float = minf(curveLength * 0.2, curveLength / float(drones.size()))
	var i := 0
	for drone in drones:
		var mod = ceil(i / 2.0) * step
		if i % 2 == 0:
			mod = -mod 
		var pos = droneCurve.sample_baked(curveLength * 0.5 + mod)
		drone.setGoalPosition(pos)
		i += 1

func executeBattle1() -> bool:
	var remainingUses = Data.of("droneyard.remainingbattleabilityuses")
	if remainingUses <= 0:
		Audio.sound("gui_err")
		return false
	
	Data.apply("droneyard.remainingbattleabilityuses", remainingUses - 1)
	
	spawnParasiteDrones()
	
	Backend.event("battle_ability_used", {"gadget": "droneyard", "ability": BATTLE_ABILITIES.keys()[BATTLE_ABILITIES.PARASITES]})
	return true

func getBattleAbilityName() -> String:
	var ability = Data.of("droneyard.battleability") as BATTLE_ABILITIES
	match ability:
		BATTLE_ABILITIES.BATTLEGRID:
			return tr("upgrades.droneyardbattlegrid.title")
		BATTLE_ABILITIES.PARASITES:
			return tr("upgrades.droneyardparasites.title")
	return ""

func remove():
	queue_free()
	for drone in get_tree().get_nodes_in_group("transport_drones"):
		drone.queue_free()


func _on_grid_drone_nest_back_animation_finished() -> void:
	$GridDroneNestBack.play("idle")
	$GridDroneNestFront.visible = false

func _on_grid_drone_nest_front_frame_changed() -> void:
	if spawningGridDrones and $GridDroneNestFront.frame == 7:
		spawnGridDrone()
