extends "res://content/gadgets/PrimaryGadget.gd"

enum Mode {NOTHING, ROOTS, SHIELD}
var mode:int = Mode.NOTHING

var battleAbilityActive := false

var plantReady := false
var producing := false
var grownAfter:float
var addedBuffs := {}

const FRUIT_OFFSETS := {
	"dome1": Vector2(10, 8),
	"dome2": Vector2(4, -5),
	"dome3": Vector2(-5, 17),
	"dome4": Vector2(-4, 14),
}

func _ready():
	$Sprite2D/Fruit.visible = false
	$Sprite2D.play("growing_" + domeId)
	Data.apply("orchard.currentgrowth", 0)
	
	Data.listen(self, "monsters.wavepresent")
	Data.listen(self, "orchard.battleshields")
	Data.listen(self, "orchard.battleroots")
	Data.listen(self, "orchard.overcharged")
	Data.listen(self, "orchard.battleabilityuses")
	if not SaveGame.currentLoadingSavegame:
		Data.apply("orchard.overcharged", false)
		Data.apply("orchard.remainingbattleuses", 0)

	for keeper in Keepers.getAll():
		Data.apply("orchard.remainingbuffduration." + keeper.playerId, 0)

	match domeId:
		"dome1":
			pass
		"dome2":
			pass
		"dome3":
			pass
		"dome4":
			position += Vector2(-2, -5)
	
	Style.init(self)
	
	Level.addTutorial(self, "orchard")
	Level.addTutorial(self, "overcharge")
	
	Achievements.addIfOpen(self, "ORCHARD_LONG")

func serialize()->Dictionary:
	var data = {
		"mode": mode,
		"battleAbilityActive": battleAbilityActive,
		"plantReady": plantReady,
		"producing": producing,
		"grownAfter": grownAfter,
		"addedBuffs": addedBuffs,
	}
	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	return data
	
func deserialize(data: Dictionary):
	mode = data["mode"]
	battleAbilityActive = data["battleAbilityActive"]
	plantReady = data["plantReady"]
	producing = data["producing"]
	grownAfter = data["grownAfter"]
	addedBuffs = data["addedBuffs"]
	
	if producing:
		$Sprite2D.play("growing_" + domeId)
		$Center/OrchardActive.play()
		
	if plantReady:
		createFruit()
	
func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"monsters.wavepresent":
			if newValue:
				var uses = Data.of("orchard.battleabilityuses")
				if Data.of("orchard.overcharged"):
					uses += Data.of("orchard.overchargeabilityuses")
				Data.apply("orchard.remainingbattleuses", uses)
			elif not SaveGame.currentLoadingSavegame:
				Data.apply("orchard.remainingbattleuses", 0)
				Data.apply("orchard.overcharged", false)
		"orchard.battleshields":
			if mode == Mode.NOTHING and newValue > 0:
				mode = Mode.SHIELD
				add_to_group("dome_ability1")
				$RootingSound.queue_free()
		"orchard.battleroots":
			if mode == Mode.NOTHING and newValue > 0:
				mode = Mode.ROOTS
				add_to_group("dome_ability1")
				$ShieldSound.queue_free()
		"orchard.overcharged":
			if plantReady:
				$Sprite2D.play("fruit_" + domeId)
			elif newValue:
				$Sprite2D.play("overcharged_" + domeId)
			else:
				$Sprite2D.play("growing_" + domeId)
		"orchard.battleabilityuses":
			if oldValue != null:
				var delta = newValue - oldValue
				if delta > 0 and Data.of("monsters.wavepresent"):
					Data.changeByInt("orchard.remainingbattleuses", delta)

func _process(delta):
	if GameWorld.softPaused():
		return
	
	var keepers = Keepers.getAll()
	for keeper in keepers:
		var key = "orchard.remainingbuffduration." + keeper.playerId
		var remainingBuffDuration = Data.ofOr(key, 0)
		if remainingBuffDuration > 0.0:
			var moveLength = keeper.moveDirectionInput.length()
			if moveLength > 0.0:
				remainingBuffDuration -= delta * moveLength * GameWorld.cycleSpeed / float(keepers.size())
			Data.apply(key, remainingBuffDuration)
			if remainingBuffDuration <= 0:
				removeBuff(keeper.playerId)
	
	if plantReady:
		return
	
	if producing and GameWorld.runStarted:
		var d:float = delta * GameWorld.cycleSpeed
		var plantGrowth = Data.of("orchard.currentgrowth") + d / grownAfter
	
		Data.apply("orchard.currentgrowth", plantGrowth)
		if plantGrowth >= 1.0:
			createFruit()
			$Center/OrchardActive.stop()
	else:
		producing = true
		grownAfter = GameWorld.getTimeBetweenWaves() * float(Data.of("orchard.growthTime"))
		if Data.of("orchard.overcharged"):
			$Sprite2D.play("overcharged_" + domeId)
		else:
			$Sprite2D.play("growing_" + domeId)
		$Center/OrchardActive.play()

func removeBuff(playerId):
	var key = playerId + ".keeper.speedbuff"
	Data.changeByInt(key, -addedBuffs[key])
	key = playerId + ".keeper.drillbuff"
	Data.changeByInt(key, -addedBuffs[key])

func canFocusUse(keeper:Keeper) -> bool:
	if plantReady:
		return true
	if canOvercharge():
		return true
	return false

func useHold(keeper:Keeper) -> bool:
	if canOvercharge():
		return tryOvercharge()
	else:
		return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	if plantReady:
		Audio.sound("apple")
		if Data.of("orchard.overcharged"):
			$Sprite2D.play("overcharged_" + domeId)
		else:
			$Sprite2D.play("growing_" + domeId)
		
		var durationCycles:float = Data.of("orchard.buffduration")
		Data.changeByInt("orchard.buffedcycles", durationCycles)
		var duration = GameWorld.getTimeBetweenWaves() * durationCycles
		if Data.ofOr("orchard.remainingbuffduration." + keeper.playerId,0.0) > 0.0:
			removeBuff(keeper.playerId)

		var addedSpeedBuff = Data.of("orchard.speedbuff")
		var key = keeper.playerId + ".keeper.speedbuff"
		Data.changeByInt(key, addedSpeedBuff)
		addedBuffs[key] = addedSpeedBuff

		var addedDrillBuff = Data.of("orchard.drillbuff")
		key = keeper.playerId + ".keeper.drillbuff"
		Data.changeByInt(keeper.playerId + ".keeper.drillbuff", addedDrillBuff)
		addedBuffs[key] = addedDrillBuff

		Data.apply("orchard.remainingbuffduration." + keeper.playerId, duration)
		plantReady = false
		Data.apply("orchard.currentgrowth", 0.0)
		$Sprite2D/Fruit.visible = false
		$Sprite2D/Fruit.pause()
		$Timer.stop()
		Backend.event("gadget_used", {"gadget": "orchard"})
		
		for keeperInstance in Keepers.getAll():
			if keeperInstance and not keeperInstance.is_connected("mined", Callable(self, "onKeeperMined")):
				keeperInstance.connect("mined", Callable(self, "onKeeperMined").bind(keeperInstance))
		return true
	else:
		return tryOvercharge()

func onKeeperMined(amount:float, keeper:Keeper):
	var key = "orchard.remainingbuffduration." + keeper.playerId
	var remainingBuffDuration = Data.of(key)
	if remainingBuffDuration > 0.0:
		remainingBuffDuration -= amount / float(Keepers.getAll().size())
		Data.apply(key, remainingBuffDuration)
		if remainingBuffDuration <= 0:
			removeBuff(keeper.playerId)

func overcharge():
	$OverchargeSound.play()
	Data.apply("orchard.overcharged", true)
	if Data.of("monsters.wavepresent"):
		Data.changeByInt("orchard.remainingbattleuses", Data.of("orchard.overchargeabilityuses"))
	Data.changeByInt("inventory.water", -1)
	Backend.event("gadget_overcharged", {"gadget": "orchard"})

func canOvercharge() -> bool:
	return Data.of("orchard.overchargeabilitystrength") > 0.0 and not Data.of("orchard.overcharged")

func createFruit():
	plantReady = true
	producing = false
	$Usable.updateFocus()
	$Sprite2D.play("fruit_" + domeId)
	$Sprite2D/Fruit.visible = false
	$Sprite2D/Fruit.play("shine_" + domeId)
	$Sprite2D/Fruit.position = FRUIT_OFFSETS.get(domeId, Vector2.ZERO)
	$Sprite2D/Fruit.show()
	_on_Timer_timeout()
	$FruitSpawnSound.play()
	$TreeTimer.start()

func _on_Timer_timeout():
	if not GameWorld.softPaused():
		$Sprite2D/Fruit.play("shine_" + domeId)
		$Sprite2D/Fruit.frame = 0
	$Timer.wait_time = 2.0 + randf() * 2.0
	$Timer.start()

func _on_TreeTimer_timeout():
	if not $Sprite2D.animation.begins_with("fruit"):
		return
	
	if not GameWorld.softPaused():
		$Sprite2D.frame = 0
	$TreeTimer.wait_time = 4.0 + randf() * 2.0
	$TreeTimer.start()

func deactivate():
	battleAbilityActive = false
	match mode:
		Mode.ROOTS:
			pass
		Mode.SHIELD:
			$ShieldEndSound.play()

func getBattleAbilityName() -> String:
	match mode:
		Mode.ROOTS:
			return tr("upgrades.orchardbattlerooting.title")
		Mode.SHIELD:
			return tr("upgrades.orchardbattleshield.title")
	return ""

func executeBattle1() -> bool:
	var additionalStrength:float = Data.of("orchard.overchargeabilitystrength")

	if mode == Mode.NOTHING:
		return false
	elif mode == Mode.ROOTS and Data.of("orchard.battlerootexplosion") > 0:
		var roots = get_tree().get_nodes_in_group("orchard-root")
		roots.shuffle()
		var exploded := false
		var i := 0
		for root in roots:
			if root.hasCatch():
				root.explode(i, additionalStrength)
				exploded = true
				i += 1
		if exploded:
			return true
	
	var remainingUses = Data.of("orchard.remainingbattleuses")
	if remainingUses <= 0:
		Audio.sound("gui_err")
		return false
	
	Data.apply("orchard.remainingbattleuses", remainingUses - 1)
	
	battleAbilityActive = true
	
	match mode:
		Mode.ROOTS:
			$RootingSound.play()
			var delay = 0.01
			var paths:Array = Level.world.getDefensivePaths("walk_medium", "left")
			paths.append_array(Level.world.getDefensivePaths("walk_medium", "right"))
			paths.shuffle()
			
			var amount = Data.of("orchard.battleroots")
			amount += round(amount * additionalStrength)
			for i in range(0, amount):
				var path = paths[i % paths.size()]
				var pos = path.curve.sample_baked(path.curve.get_baked_length() * (0.5 +randf() * 0.3)) + path.position
				$Tween.interpolate_callback(self, delay, "spawnRoot", pos)
				delay += 0.2 + randf() * 0.15
			$Tween.start()
		Mode.SHIELD:
			$ShieldSound.play()
			var delay = 0.01
			
			for existingShield in get_tree().get_nodes_in_group("orchard-shield"):
				existingShield.dissolve(delay)
				delay += randf() * 0.08
			
			var hp = Data.of("orchard.battleshieldhp")
			hp += round(hp * additionalStrength)
			
			var cupolaLength = Level.dome.getCupolaLength()
			var shieldSpacingPx:float = 50.0
			var shieldCount = ceil((cupolaLength - shieldSpacingPx) / shieldSpacingPx) # leave a half shield length to each side
			var step = 0.66 / float(shieldCount - 1)
			var offsets = []
			for i in shieldCount:
				offsets.append(0.17 + step * i)
			offsets.shuffle()
			for offset in offsets:
				var shield = preload("res://content/gadgets/orchard/OrchardShield.tscn").instantiate()
				var pos = Level.dome.getCupolaPosition(offset)
				var finalOffset = 5 * Vector2.UP.rotated(pos.z)
				shield.position.x = pos.x + finalOffset.x
				shield.position.y = pos.y + finalOffset.y
				shield.rotation = pos.z
				Level.dome.add_child(shield)
				shield.init(delay, 35, hp)
				delay += 0.1 + randf() * 0.15
			
			if Data.of("orchard.battleshields") >= 2:
				step = 0.7 / float(shieldCount)
				offsets.clear()
				for i in shieldCount + 1:
					offsets.append(0.15 + step * i)
				offsets.shuffle()
				for offset in offsets:
					var shield = preload("res://content/gadgets/orchard/OrchardShield.tscn").instantiate()
					shield.z_index -= 1
					var pos = Level.dome.getCupolaPosition(offset)
					var finalOffset = 18 * Vector2.UP.rotated(pos.z)
					shield.position.x = pos.x + finalOffset.x
					shield.position.y = pos.y + finalOffset.y
					shield.rotation = pos.z 
					Level.dome.add_child(shield)
					shield.init(delay, 48, hp)
					delay += 0.1 + randf() * 0.15
	
	Backend.event("battle_ability_used", {"gadget": "orchard", "ability": Mode.keys()[mode]})
	return true

func spawnRoot(pos:Vector2):
	var root = preload("res://content/gadgets/orchard/OrchardRoot.tscn").instantiate()
	pos.y += 2
	root.position = pos
	Level.viewports.addMonster(root)

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()

func remove():
	queue_free()
