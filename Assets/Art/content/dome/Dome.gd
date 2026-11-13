extends Node2D

class_name Dome

@onready var ArtifactDropPoint = get_node("ArtifactDropPoint")
@onready var RelicDropPoint = get_node("RelicDropPoint")
@onready var EggDropPoint = get_node("EggDropPoint")
@onready var PiercePoints = get_node("PiercePoints")
@onready var MeleeTargets = get_node("MeleeTargets")
@onready var ProjectileTargets = get_node("ProjectileTargets")
@onready var cracks_overlay = $CracksOverlay

var primaryWeapon:String
@export var techId: String
var collapsed := false

var damageOnWave:float
var autohealOnWave:float
var remainingHeals:int

var autoRepairAmount:float = 0.0

var showcaseMode := false

func _ready():
	Style.init(self)
	
	Level.addTutorial(self, "stationdefend")
	Level.addTutorial(self, "repair1")
	Level.addTutorial(self, "repair2")
	
	Achievements.addIfOpen(self, "RESOURCES_COBALTSTACK")
	Achievements.addIfOpen(self, "RESOURCES_COBALTRESCUE")
	Achievements.addIfOpen(self, "DOME_LOWHEALTH")

	if GameWorld.isLunarNewYear:
		for spot in get_tree().get_nodes_in_group("dome-decoration"):
			var lantern := Sprite2D.new()
			lantern.texture = preload("res://content/dome/fluffobjects/lunarlamp.png")
			spot.add_child(lantern)
			Style.init(lantern)

func init():
	$CupolaPath.visible = true
	$WeaponContainer.visible = true
	$CracksOverlay.visible = true
	$CollapseSprite.visible = false
	$CollapseParticles.emitting = false
	$Cellar/RelicActivation.play("none")
	$Cellar/SpinningRelic.play("none")
	
	var domeData = Data.gadgets.get(techId)
	primaryWeapon = domeData.get("primaryweapon")
	GameWorld.addUpgrade(primaryWeapon)
	
	# transform the curve points, so interpolation applies to global space
	for c in $MeleeTargets.get_children():
		for i in range(0, c.curve.get_point_count()):
			c.curve.set_point_position(i, c.curve.get_point_position(i) + global_position)
	
	Data.listen(self, "dome.baserepair")
	Data.listen(self, "dome.healthfractionrepair")
	Data.listen(self, "dome.reducedhealth")
	Data.listen(self, "monsters.wavepresent")
	Data.listen(self, "dome.mainweapons", true)

func unlisten():
	Data.unlisten(self, "dome.baserepair")
	Data.unlisten(self, "dome.healthfractionrepair")
	Data.unlisten(self, "monsters.wavepresent")
	Data.unlisten(self, "dome.mainweapons")
	Data.unlisten(self, "dome.reducedhealth")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"dome.mainweapons":
			var primaryWeapons = get_tree().get_nodes_in_group("primaryWeapon")
			var diff = newValue - primaryWeapons.size()
			if diff > 0:
				for _i in diff:
					addWeapon()
			elif diff < 0:
				for i in abs(diff):
					primaryWeapons[i].remove()
		"dome.reducedhealth":
			if oldValue != null:
				var change = oldValue - newValue
				if change > 0:
					var maxhealth = Data.of("dome.maxhealth")
					Data.apply("dome.maxhealth", maxhealth + change)
					Data.changeDomeHealth(change)
					Data.apply("dome.reducedhealth", 0)
		"dome.baserepair":
			if newValue != 0:
				Data.changeDomeHealth(newValue)
		"dome.healthfractionrepair":
			if newValue != 0:
				Data.changeDomeHealth(newValue * Data.of("dome.maxHealth"))
		"monsters.wavepresent":
			if newValue:
				GameWorld.incrementRunStat("damage_taken", damageOnWave)
				damageOnWave = 0.0
				autohealOnWave = 0.0
				remainingHeals = 1

func _process(delta):
	if GameWorld.paused:
		return
	
	if autoRepairAmount > 0.0:
		var repair = clamp(100 * delta, 0, autoRepairAmount)
		autoRepairAmount -= repair
		Data.changeDomeHealth(repair)
	
	var invlunerableTime = Data.of("dome.invulnerabletime")
	if invlunerableTime > 0:
		Data.apply("dome.invulnerabletime", invlunerableTime - delta)

func onGameLost():
	if collapsed:
		return
	
	collapsed = true
	$CollapseSprite.frame = 0
	$CollapseSprite.visible = true
	$CollapseShards.collapse()
	$Tween.interpolate_property($CollapseSprite, "frame", 0, 11, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.0)
	$Tween.interpolate_property($CollapseParticles, "emitting", false, true, 0.0, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.0)
	$Tween.start()
	$Background.visible = false
	$Foreground.visible = false
	$Shield.visible = false
	$WartContainer.visible = false
	$Station.visible = false
	$PrimaryGadgetContainer.visible = false
	$Shredder.visible = false
	$CupolaPath.visible = false
	$WeaponContainer.visible = false
	$CracksOverlay.hide()
	
	for spot in get_tree().get_nodes_in_group("dome-decoration"):
		spot.visible = false
	
	for pet in get_tree().get_nodes_in_group("pets"):
		pet.visible = false

func getDropTarget(dropType:String):
	match dropType:
		CONST.POWERCORE:
			return Level.dome.ArtifactDropPoint
		CONST.GADGET:
			return Level.dome.ArtifactDropPoint
		CONST.RELIC:
			return Level.dome.RelicDropPoint
		CONST.EGG:
			return Level.dome.EggDropPoint
		CONST.IRON:
			return $Shredder
		CONST.WATER:
			return $Shredder
		CONST.SAND:
			return $Shredder
		CONST.PACK:
			return $Shredder

func getProjectileTargetProvider():
	return $ProjectileTargets

func getMeleeTarget(variant):
	match variant:
		CONST.LEFT: return $MeleeTargets/Left
		CONST.RIGHT: return $MeleeTargets/Right
		CONST.TOP: return $MeleeTargets/Top
	return null

func getFrontAttackPosition(variant) -> Vector2:
	var point:Vector2
	match variant:
		"left": point = $FrontAttackPoints/LeftPoint1.global_position
		"right": point = $FrontAttackPoints/RightPoint1.global_position
		_: point = $FrontAttackPoints/CenterPoint1.global_position
	var offset := Vector2.RIGHT.rotated(randf()*TAU)
	return point + offset * 16 * randf()

# offset between 0.0 and 1.0, will return the global position on the domes cupola
func getCupolaPosition(offset:float) -> Vector3:
	var bl = $CupolaPath.curve.get_baked_length()
	var pos = $CupolaPath.curve.sample_baked(offset * bl)
	var p1 = $CupolaPath.curve.sample_baked((offset-0.01) * bl)
	var p2 = $CupolaPath.curve.sample_baked((offset+0.01) * bl)
	var angle = (p2 - p1).angle()
#	var angle = (pos - pos * $CupolaPath.axisModulation - $CupolaPath.getRotationCenter()).angle() + PI*0.5
	return Vector3(pos.x, pos.y, angle)

func getCupolaClosestPos(pos:Vector2) -> Vector2:
	return $CupolaPath.curve.get_closest_point(pos)

func getCupolaLength() -> float:
	return $CupolaPath.curve.get_baked_length()

func addWeapon():
	var w = load("res://content/weapons/" + primaryWeapon + "/" + primaryWeapon.capitalize() + ".tscn").instantiate()
	$WeaponContainer.add_child(w)
	w.showcaseMode = showcaseMode
	w.init($CupolaPath)
	$Station.addControlledWeapon(w)

func getWeapons():
	return $WeaponContainer.get_children()

func requestProjectileDamage(rawDamage:int, pos:Vector2, requester):
	var remainingDamage = $Shield.absorbDamage(rawDamage * float(Data.of("dome.incomingdamagemodifier")), pos)
	var damage:float = remainingDamage * clamp((1.0 - Data.of("dome.projectiledamagereduction")), 0, 1)
	if damage > 0.0:
		Data.changeDomeHealth(-damage)
		cracks_overlay.hit(pos, damage)
		handleSustainedDamage(damage)
		requester.domeAcceptsDamage()
	elif damage == 0.0:
		requester.domeAbsorbsDamage()
	else:
		requester.domeReflectsDamage()
	
	trackDamage(requester.damageSource, damage)

func trackDamage(source, value):
	#if source == "Area2D":
	#	breakpoint
	GameWorld.trackedDamageReceived[source] = GameWorld.trackedDamageReceived.get(source, 0) + value
	Level.monsters.domeLostHealth(value)

func requestMeleeDamage(rawDamage:int, pos:Vector2, requester):
	var remainingDamage = $Shield.absorbDamage(rawDamage * float(Data.of("dome.incomingdamagemodifier")), pos)
	var damage:float = remainingDamage * clamp((1.0 - Data.of("dome.meleedamagereduction")), 0, 1)
	var thornDamage = Data.of("dome.meleethorndamage")
	if damage > 0.0:
		Data.changeDomeHealth(-damage)
		handleSustainedDamage(damage)
		cracks_overlay.hit(pos, damage)
	
	if thornDamage > 0.0 or damage <= 0.0:
		# Play thorn/reflect vfx:
		$Shield.zapMonsters([requester], 5.0)
		requester.domeReflectsDamage(thornDamage, 1.0, 1.0, 0.0)
	else:
		requester.domeAcceptsDamage()
	
	trackDamage(requester.damageSource, damage)

func requestBeamDamage(rawDamage:int, pos:Vector2, requester):
	var remainingDamage = $Shield.absorbDamage(rawDamage * float(Data.of("dome.incomingdamagemodifier")), pos)
	var reduction = 0.5 * (Data.of("dome.meleedamagereduction") + Data.of("dome.projectiledamagereduction"))
	var damage:float = remainingDamage * clamp((1.0 - reduction), 0, 1)
	if damage > 0.0:
		Data.changeDomeHealth(-damage)
		handleSustainedDamage(damage)
		cracks_overlay.hit(pos, damage)
	
	if damage > 0.0:
		requester.domeAcceptsDamage()
		trackDamage(requester.damageSource, damage)


func addGadget(gadget, slot:String):
	match slot:
		"primarygadget":
			gadget.domeId = techId
			$PrimaryGadgetContainer.add_child(gadget)
		"cellar":
			placeInCellar(gadget)
		"domesurface":
			$CupolaPath.add_child(gadget)
			gadget.init($CupolaPath)
		"domebackside":
			$BacksideContainer.add_child(gadget)
		_:
			Logger.error("cannot add gadget to dome, unknown slot", "Dome.addGadget", {"slot": slot, "gadget": str(gadget)})

func removePrimaryGadget():
	for c in $PrimaryGadgetContainer.get_children():
		c.remove()

func placeInCellar(gadget):
	var container
	if $Cellar/ContainerLeft.get_child_count() > 0:
		container = $Cellar/ContainerRight
	elif $Cellar/ContainerRight.get_child_count() > 0:
		container = $Cellar/ContainerLeft
	else:
		container = $Cellar/ContainerLeft
	
	# order is relevant. Flip first, as some gadgets do intialisation different depending on whether they are flipped or not.
	if container.position.x < 0:
		gadget.flip()
	container.add_child(gadget)

func autoheal():
	$HealEffect.start()
	$Autoheal.play()

func handleSustainedDamage(damage:float):
	damageOnWave += damage
	if remainingHeals > 0:
		var threshold = Data.of("dome.autohealdamagethreshold")
		if threshold > 0.0 and (damageOnWave - autohealOnWave) >= threshold:
			autoRepairAmount = Data.of("dome.autohealamount")
			remainingHeals -= 1
			autohealOnWave += autoRepairAmount
			autoheal()

func ambience() -> AudioStreamPlayer:
	return $Ambience as AudioStreamPlayer

func uiRender():
	$Cellar.queue_free()

func _on_RelicDropPoint_relic_recovered():
	InputSystem.shake(80, 2, 5, $Cellar/RelicActivation.global_position)
	$Cellar/RelicActivation.play("activate")
	$Cellar/RelicActivation/Inserted.play()

func _on_relic_activation_animation_looped() -> void:
	_RelicActivationAnimationFinishedCheck()

func _on_RelicActivation_animation_finished() -> void:
	_RelicActivationAnimationFinishedCheck()

func _RelicActivationAnimationFinishedCheck() -> void:
	if $Cellar/RelicActivation.animation == "activate":
		$Cellar/RelicActivation/Ambience.play()
		$Cellar/RelicActivation.play("running")
		$Cellar/SpinningRelic.play("spinning")
