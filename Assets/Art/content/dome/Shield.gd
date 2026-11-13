extends Sprite2D

enum Mode {NOTHING, BLAST, REFLECT, INVULNERABLE}
var mode:int = Mode.NOTHING

var monstersInBlastArea := []
var projectilesInReflectArea := []

var active := false
var maxAdditionalCharge := 0.0
var chargedAfter:float = 1.0
var blastSpriteFrame:float
var lastDuration := 0.0

var DESTRUCTION_PREVENTION_COOLDOWN := 3

@onready var blastArc:TeslaArc = $Blast/BlastArc
@onready var blastShootArc:TeslaArc = $Blast/BlastShootArc
@onready var blastParticles:GPUParticles2D = $Blast/ShieldBlastParticles

func _ready():
	$Blast.visible = false
	$Reflect.visible = false
	$Invulnerable.visible = false
	$OverchargeShield.visible = false
	$Reflect.monitoring = false
	$Reflect/CollisionPolygon2D.disabled = true
	$Blast.monitoring = false
	$Blast/CollisionPolygon2D.disabled = true
	
	visible = false
	set_process(false)
	Data.listen(self, "shield.stage", true)
	Data.listen(self, "shield.overchargestrength", true)
	Data.listen(self, "shield.battleuses")
	Data.apply("shield.strength", 0)
	Data.apply("shield.additionalstrength", 0)
	Data.apply("shield.remainingbattleuses", 0)
	Data.apply("shield.remainingabilityduration", 0)
	Data.apply("shield.dorecharge", true)
	
	Achievements.addIfOpen(self, "SHIELD_STRONG")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"shield.overchargestrength":
			maxAdditionalCharge = newValue
		"monsters.wavepresent":
			if newValue == oldValue:
				# happens when loading a game. Special case because overcharge should not be reset.
				chargedAfter = GameWorld.getTimeBetweenWaves() * float(Data.of("shield.growthTime"))
				return
			
			if newValue:
				Data.apply("shield.remainingbattleuses", Data.of("shield.battleuses"))
			else:
				Data.apply("shield.overcharged", false)
				Data.apply("shield.additionalstrength", 0.0)
				Data.apply("shield.remainingbattleuses", 0)
				Data.apply("shield.remainingabilityduration", 0)
				
				chargedAfter = GameWorld.getTimeBetweenWaves() * float(Data.of("shield.growthTime"))
				var currentCooldown = Data.of("shield.battlepreventioncooldown")
				if currentCooldown == DESTRUCTION_PREVENTION_COOLDOWN:
					Data.apply("shield.dorecharge", false)
				else:
					Data.apply("shield.dorecharge", true)
				if currentCooldown > 0:
					Data.apply("shield.battlepreventioncooldown", max(0, currentCooldown - 1))
		"shield.overcharged":
			if newValue:
				Data.apply("shield.additionalstrength", maxAdditionalCharge)
				$OverchargeShield.visible = true
				Data.apply("shield.strength", Data.of("shield.maxStrength"))
		"shield.battlereflect":
			if mode == Mode.NOTHING and newValue:
				add_to_group("dome_ability1")
				$Reflect.monitoring = true
				$Reflect/CollisionPolygon2D.disabled = false
				mode = Mode.REFLECT
		"shield.battleblast":
			if mode == Mode.NOTHING and newValue:
				add_to_group("dome_ability1")
				$Blast.monitoring = true
				$Blast/CollisionPolygon2D.disabled = false
				mode = Mode.BLAST
		"shield.battleinvulnerable":
			if mode == Mode.NOTHING and newValue:
				add_to_group("dome_ability1")
				mode = Mode.INVULNERABLE
		"shield.stage":
			if newValue > 0:
				if not visible:
					visible = true
					self_modulate.a = 0.0
					set_process(true)
					Data.listen(self, "shield.battlereflect")
					Data.listen(self, "shield.battleblast")
					Data.listen(self, "shield.battleinvulnerable")
					Data.listen(self, "monsters.wavepresent")
					Data.listen(self, "shield.overcharged")
					Data.apply("shield.battlepreventioncooldown", 0)
			else:
				visible = false
				set_process(false)
		"shield.battleuses":
			if oldValue != null:
				var delta = newValue - oldValue
				if delta > 0 and Data.of("monsters.wavepresent"):
					Data.changeByInt("shield.remainingbattleuses", delta)

func absorbDamage(rawDamage, pos:Vector2) -> float:
	if not visible:
		return rawDamage

	if active and mode == Mode.INVULNERABLE:
		return 0.0

	var add = Data.of("shield.additionalstrength")
	var remainingAfterAdditional = max(0, rawDamage - add)
	add = max(add - rawDamage, 0)
	Data.apply("shield.additionalstrength", add)
	
	var s = Data.of("shield.strength")
	var remaining = max(0.0, remainingAfterAdditional - s)
	var newS = max(s - remainingAfterAdditional, 0)
	Data.apply("shield.strength", newS)
	
	# handle fire on depletion from invulnerable
	if newS == 0.0 and s > 0.0 and Data.of("shield.battleactivateondepletion"):
		if active:
			var duration = getBattleAbilityDuration()
			duration += duration - $Tween.tell()
			lastDuration = duration
			active = true
			$Tween.stop_all()
			$Tween.remove_all()
			$Tween.interpolate_callback(self, duration, "deactivate")
			$Tween.start()
		else:
			executeBattle1(0, false)
			if active and mode == Mode.INVULNERABLE:
				return 0.0
	
	# handle destruction preventions from invulnerable
	var preventionTime = Data.of("shield.battledestructionprevention")
	if preventionTime > 0 and remaining + 1.0 > Data.of("dome.health") and Data.of("shield.battlepreventioncooldown") == 0:
		executeBattle1(preventionTime, false)
		Data.apply("shield.battlepreventioncooldown", DESTRUCTION_PREVENTION_COOLDOWN)
		Data.apply("dome.health", 2.0)
		Data.changeByInt("shield.absorbeddamage", rawDamage)
		return 0.0
	if s > 0.0:
		Data.changeByInt("shield.absorbeddamage", remaining * 0.5)
		return remaining * 0.5
	else:
		Data.changeByInt("shield.absorbeddamage", remaining)
		return remaining

func _process(delta):
	if GameWorld.paused:
		return
	
	# This has to run all the time as it is eventually also used by thorns damage
	lastZapTime += delta
	
	var currentShieldStrength = Data.of("shield.strength")
	var maxShieldStrength = Data.of("shield.maxStrength")
	var filling:float = currentShieldStrength / maxShieldStrength
	self_modulate.a = min(filling, 1.0)
	if $OverchargeShield.visible:
		$OverchargeShield.modulate.a = Data.of("shield.additionalstrength") / float(maxAdditionalCharge)
	
	if not GameWorld.softPaused() and Data.of("shield.dorecharge"):
		var rechargeRate = maxShieldStrength / chargedAfter
		currentShieldStrength = min(currentShieldStrength + delta * GameWorld.cycleSpeed * rechargeRate, maxShieldStrength)
		
		Data.apply("shield.strength", currentShieldStrength)
	
	if active:
		Data.apply("shield.remainingabilityduration", lastDuration - $Tween.tell())
		match mode:
			Mode.BLAST:
				var dmg = Data.of("shield.battleblastdamage") * delta
				var stun = Data.of("shield.battleblaststun")
				playBlastAnimation(delta)
				for area in monstersInBlastArea.duplicate():
					area.hit("shieldbattleelectroblast", dmg, stun, false)
			Mode.INVULNERABLE:
				pass
			Mode.REFLECT:
				var reflected := false
				for area in projectilesInReflectArea:
					if not is_instance_valid(area):
						continue
					
					area.domeReflectsDamage(0.0, Data.of("shield.battlereflectspeedup"), 2.0)
					$Reflect/ReflectProjectileSound2.play()
					reflected = true
				
				if reflected:
					# Animate the reflection effect
					$Reflect/Tween.remove_all()
					$Reflect/ReflectSprite.modulate = Color(1,1,1,1)
					$Reflect/Tween.interpolate_property($Reflect/ReflectSprite, "scale", Vector2(1.05,1.05), Vector2(1,1), 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
					$Reflect/Tween.start()
					
				projectilesInReflectArea.clear()

var lastArcTime := 0.0
var nextArcTime := 0.1

var lastZapTime := 0.0
var nextZapTime := 0.1

func playBlastAnimation(delta):
	# Particle around cupola vfx
	var particlePos : Vector3 = Level.dome.getCupolaPosition(wrapf(Time.get_ticks_msec()/100.0, 0.05, 0.97))
	blastParticles.global_position = Vector2(particlePos.x, particlePos.y)+Vector2(0, -10).rotated(particlePos.z)
	blastParticles.rotation = particlePos.z
	var particleAmount = int(remap(Data.of("shield.battleblastdamage"), 30.0, 80.0, 100, 300))
	if particleAmount != blastParticles.amount:
		blastParticles.amount = particleAmount
	
	# Shield Arc vfx
	lastArcTime += delta
	if lastArcTime > nextArcTime:
		lastArcTime = 0.0
		nextArcTime = randf_range(0.05, 0.13) * remap(Data.of("shield.battleblastdamage"), 30.0, 80.0, 1.0, 0.5)
		
		var start = randf()*0.6+0.1
		var startPos : Vector3 = Level.dome.getCupolaPosition(start)
		var endPos : Vector3 = Level.dome.getCupolaPosition(min(start + max(0.1, randf()*0.4), 0.9))
		blastArc.global_position = Vector2(startPos.x, startPos.y) + Vector2(0, -10).rotated(startPos.z)
		blastArc.target = Vector2(endPos.x, endPos.y) + Vector2(0, -10).rotated(endPos.z)
		blastArc.forceCreateArc()
	
	# Monster Zapping when dealing damage vfx and sound
	if not monstersInBlastArea.is_empty():
		var zapTimeMod = remap(Data.of("shield.battleblastdamage"), 30.0, 80.0, 1.0, 0.5)
		zapMonsters(monstersInBlastArea, zapTimeMod)

var bufferedMonsters := []
func zapMonsters(monsters:Array, zapTimeMod := 1.0, force := false):
	for m in monsters:
		if not bufferedMonsters.has(m):
			bufferedMonsters.append(m)
	if not force and lastZapTime < nextZapTime*zapTimeMod:
		return
	lastZapTime = 0.0
	nextZapTime = randf_range(0.03, 0.08)
	$Blast/BlastTick.play()
	for m in bufferedMonsters:
		if not is_instance_valid(m) or m.dead:
			continue
		var targetPos = m.getCenter()+Vector2(randf_range(-10, 10), randf_range(-10, 10))
		var startPos = Level.dome.getCupolaClosestPos(targetPos)
		blastShootArc.global_position = startPos + startPos.direction_to(targetPos)*8.0
		blastShootArc.target = targetPos
		blastShootArc.forceCreateArc()
	bufferedMonsters.clear()

func _on_BlastArea_area_entered(area):
	if area.is_in_group("monster") and not monstersInBlastArea.has(area):
		monstersInBlastArea.append(area)
		area.connect("died", Callable(self, "monsterDied").bind(area))

func monsterDied(monster):
	monstersInBlastArea.erase(monster)

func _on_BlastArea_area_exited(area):
	if area.is_in_group("monster"):
		monstersInBlastArea.erase(area)
		area.disconnect("died", Callable(self, "monsterDied"))

func _on_ReflectArea_area_entered(area):
	if area.is_in_group("projectile"):
		projectilesInReflectArea.append(area)

func _on_ReflectArea_area_exited(area):
	if area.is_in_group("projectile"):
		projectilesInReflectArea.erase(area)

func executeBattle1(extraTime := 0.0, useCharge := true) -> bool:
	if mode == Mode.NOTHING:
		return false
	
	if active:
		return false
	
	if useCharge:
		var remainingUses = Data.of("shield.remainingbattleuses")
		if remainingUses <= 0:
			Audio.sound("gui_err")
			return false
		Data.apply("shield.remainingbattleuses", remainingUses - 1)
	
	var duration = getBattleAbilityDuration() + extraTime
	lastDuration = duration
	active = true
	Audio.sound("gui_toggle")
	
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_callback(self, duration, "deactivate")
	$Tween.start()
	
	match mode:
		Mode.BLAST:
			$Blast.visible = true
			blastSpriteFrame = 49.0
			$Blast/BlastSound.play()
			$Blast/BlastLoopSound.play()
		Mode.INVULNERABLE:
			$Invulnerable.activate()
		Mode.REFLECT:
			$Reflect/Tween.remove_all()
			$Reflect.visible = true
			$Reflect/ReflectSprite.modulate = Color(1,1,1,1)
			$Reflect/ReflectSprite.scale = Vector2(1,1)
			$Reflect/ReflectSound.play()
			$Reflect/InitiateReflectSound.play()
	Backend.event("battle_ability_used", {"gadget": "shield", "ability": Mode.keys()[mode]})
	return true

func getBattleAbilityName() -> String:
	match mode:
		Mode.BLAST:
			return tr("upgrades.shieldbattleelectroblast.title")
		Mode.INVULNERABLE:
			return tr("upgrades.shieldbattleinvulnerable.title")
		Mode.REFLECT:
			return tr("upgrades.shieldbattlereflect.title")
	return ""

func getBattleAbilityDuration() -> float:
	var duration = Data.of("shield.battleabilityduration")
	if Data.of("shield.strength") <= 0.0:
		duration += Data.of("shield.battleadditionalabilitydurationafterdepletion")
	return duration

func deactivate():
	active = false
	match mode:
			Mode.BLAST:
				$Blast.visible = false
				$Blast/BlastLoopSound.stop()
				$Blast/BlastEndSound.play()
			Mode.INVULNERABLE:
				$Invulnerable.deactivate()
			Mode.REFLECT:
				var duration = 0.15
				$Reflect/Tween.remove_all()
				$Reflect/ReflectSprite.scale = Vector2(1,1)
				$Reflect/Tween.interpolate_property($Reflect/ReflectSprite, "modulate", Color(1,1,1,1), Color(1,1,1,0), duration, Tween.TRANS_LINEAR)
				$Reflect/Tween.interpolate_callback($Reflect, duration, "hide")
				$Reflect/Tween.start()
	
	Data.apply("shield.remainingabilityduration", 0.0)

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()
