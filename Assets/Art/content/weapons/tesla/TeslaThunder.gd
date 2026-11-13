extends Node2D

@export var noise : FastNoiseLite

var initialDamage:float
var orbDamage:float
var initialStun:float
var baseRadius:float
var radius := 1.0
var perfect := false

var strength:float
var accumulatedDamageToReduceStrength:float

var polarFx : Node2D = null
var polarFxBackground : Node2D = null
var teslaCrystalParticle : GPUParticles2D = null
var persistent := false
var canPlayDamageSound := true
var canShowArc := true
var tickPower := 0.0
var perfectOrb := false


func _ready():
	teslaCrystalParticle = preload("res://content/weapons/tesla/TeslaOrbParticle.tscn").instantiate()
	Level.map.addPixelEffect(teslaCrystalParticle)

func start(initialDamage:float, radius:float, strength:float):
	$Area2D/Collision.shape.radius = radius
	self.baseRadius = radius
	self.initialDamage = initialDamage
	self.orbDamage = Data.of("tesla.orbdamage")
	self.initialStun = initialDamage * 0.035
	self.strength = strength
	
	get_tree().connect("physics_frame", Callable(self, "dealInitialDamage").bind(), CONNECT_ONE_SHOT)
	
	persistent = strength > 0.0
	if persistent:
		polarFx = preload("res://content/weapons/tesla/TeslaPolarFx.tscn").instantiate()
		Level.map.addPixelEffect(polarFx)
		polarFx.setScale(radius*0.1)
		
		polarFxBackground = preload("res://content/weapons/tesla/TeslaPolarBackgroundFx.tscn").instantiate()
		Level.map.add_child(polarFxBackground)
		polarFxBackground.setScale(radius*0.1)
	
		$OrbLoop.play()
		match int(Data.of("tesla.persistancesound")):
			1:
				$OrbOnStart1.play()
			2:
				$OrbOnStart2.play()
			3:
				$OrbOnStart3.play()

func dealInitialDamage():
	var didHitSomething := false
	for monster in $Area2D.get_overlapping_areas():
		playHitSound(monster)
		var source = "tesla"
		if not persistent and Data.of("tesla.persistance") > 0.0:
			source = "teslaquickshot"
		monster.hit(source, initialDamage, 0)
		monster.sustainStun(initialStun, 0.5)
		didHitSomething = true
	if didHitSomething:
		var newHitSound = preload("res://content/weapons/tesla/sounds/TeslaHitSound.tscn").instantiate()
		newHitSound.position = global_position
		Level.viewports.addElement(newHitSound)
	
	if not persistent:
		die()

func getMonstersToDamage() -> Array:
	if persistent:
		return $Area2D.get_overlapping_areas()
	else:
		return []

func damageMonsters(monsters:Array, delta:float, stunStrength:float):
	var fraction = 1.0 / float(monsters.size())
	for monster in monsters:
		playHitSound(monster)
		var damageToMonster = delta * orbDamage * fraction
		monster.hit("teslaorbs", damageToMonster, stunStrength)
		accumulatedDamageToReduceStrength += damageToMonster
	

func _physics_process(delta):
	if GameWorld.paused:
		return
	
	if perfectOrb:
		$VFX.show()
	else:
		$VFX.visible = accumulatedDamageToReduceStrength > 2.0
	teslaCrystalParticle.emitting = accumulatedDamageToReduceStrength > 2.0 
	
	var strengthBaseReduction = delta * (0.5 + strength * 0.05)
	var strengthReductionFromDamage = accumulatedDamageToReduceStrength * delta * 0.3
	accumulatedDamageToReduceStrength *= (1.0 - delta * 5)
	
	if not $StrengthenTween.is_active():
		strength = strength - (strengthBaseReduction + strengthReductionFromDamage)
	else:
		$VFX.show()
	var timeUntilWaveMod:float = sqrt(max(0, Data.of("monsters.wavecooldown") - 10))
	strength -= timeUntilWaveMod * delta
	
	var sizeMod = pow(max(0.0, strength) / PI, 0.4)
	radius = min(100, sizeMod * baseRadius + 10)
	teslaCrystalParticle.process_material.emission_sphere_radius = radius-6
	var particle_amount = round(radius * 1.2)
	if abs(teslaCrystalParticle.amount - particle_amount) > 5:
		teslaCrystalParticle.amount = int(particle_amount)
	$Area2D/Collision.shape.radius = radius
	
	if strength <= 0.0:
		die()


func die():
	set_process(false)
	set_physics_process(false)
	if polarFx:
		polarFx.end()
		polarFxBackground.end()
	if teslaCrystalParticle:
		teslaCrystalParticle.get_node("End").end()
	if int(Data.of("tesla.persistancesound")) > 0:
		var orbEndSound = preload("res://content/weapons/tesla/sounds/TeslaOrbLoopEnd.tscn").instantiate()
		orbEndSound.position = global_position
		Level.viewports.addElement(orbEndSound)
	queue_free()


func _process(delta):
	updateVisualMovingArcs(delta)
	updateVisualCenterArcs(delta)
	updateVisualCircle(delta)

func strengthen(amount:float, strengtheningPosition:Vector2):
	var newPos = lerp(position, strengtheningPosition, 1.0 - strength / (strength + amount))
	$StrengthenTween.interpolate_property(self, "energyFieldPower", energyFieldPower, 1, 0.2, Tween.TRANS_QUINT, Tween.EASE_OUT)
	$StrengthenTween.interpolate_property(self, "position", position, newPos, 0.2, Tween.TRANS_QUINT, Tween.EASE_OUT)
	$StrengthenTween.interpolate_property(self, "strength", strength, min(100, strength+amount), 0.4, Tween.TRANS_QUINT, Tween.EASE_OUT)
	$StrengthenTween.start()


@onready var effectInner = $VFX/EffectInner
@onready var arcFollowInner = $VFX/EffectInner/ArcGroupFollow
@onready var effectOuter = $VFX/EffectOuter
@onready var arcFollowOuter = $VFX/EffectOuter/ArcGroupFollow
var arcPosTime := 0.0
func updateVisualMovingArcs(delta):
	arcPosTime = wrapf(arcPosTime+delta, 0.0, 100.0)
	var rotSpeed := remap(noise.get_noise_1d(50+arcPosTime*200.0), -1, 1, -0, 25)
	var reverseOuter : float = sign(noise.get_noise_1d(150+arcPosTime*20.0))
	var reverseInner : float = sign(noise.get_noise_1d(250+arcPosTime*50.0))
	effectInner.rotation = wrapf(effectInner.rotation+(delta*rotSpeed*0.9*reverseInner), -PI, PI)
	effectOuter.rotation = wrapf(effectOuter.rotation-(delta*rotSpeed*0.4*reverseOuter), -PI, PI)
	
	
	var interval = remap(clamp(radius, 10, 100), 10, 100, 6, 14)
	var lbst = remap(clamp(radius, 10, 100), 10, 100, 6, 10)
	var dist = radius*0.86
	
	arcFollowInner.modulate.a = 1.0#(currentLifetime*0.3)+0.8
	arcFollowInner.interval = interval
	arcFollowInner.lengthBasedSpawnThreshold = lbst
	arcFollowInner.position.x = dist * 0.75 * clamp(2.5 + noise.get_noise_1d(arcPosTime*100.0)*4.0, -1, 1)
	arcFollowInner.extraPower = energyFieldPower*0.5+1
	
	arcFollowOuter.modulate.a = 1.0#(currentLifetime*0.3)+0.8
	arcFollowOuter.interval = interval
	arcFollowOuter.lengthBasedSpawnThreshold = lbst
	arcFollowOuter.position.x = dist * clamp(0.5 + noise.get_noise_1d((arcPosTime+50.0)*100.0)*4.0, -1, 1)
	arcFollowOuter.extraPower = energyFieldPower*0.5+1


@onready var arc_group = $VFX/ArcGroup
@onready var arc_group_2 = $VFX/ArcGroup2
func updateVisualCenterArcs(delta):
	arc_group.global_position = arcFollowInner.global_position
	arc_group.target = arcFollowOuter.global_position#global_position+Vector2.RIGHT.rotated(randf()*TAU)*radius
	arc_group_2.global_position = global_position#+(Vector2.RIGHT.rotated(randf()*TAU)*radius*0.2)
	arc_group_2.target = global_position+Vector2.RIGHT.rotated(randf()*TAU)*radius
	arc_group_2.forkSpawnArea = Vector2.ONE*radius*0.2
	arc_group.extraPower = energyFieldPower*0.3+1.0
	arc_group_2.extraPower = energyFieldPower*0.3+1.0
	teslaCrystalParticle.self_modulate = lerp(Color.WHITE, Color(2,2,2,1), energyFieldPower*0.5)


var energyFieldPower := 1.0
func updateVisualCircle(delta):
	energyFieldPower = lerp(energyFieldPower, 0.0, delta*6)
	
	if teslaCrystalParticle:
		teslaCrystalParticle.position = global_position
	
	if polarFx:
		polarFx.setPower(remap(energyFieldPower, 0, 1, 0.93, 1.1)+tickPower)
		polarFx.position = global_position
		polarFx.setScale(radius*0.1)
		polarFx.rotation = snapped(wrapf(polarFx.rotation+delta, 0, TAU), TAU*0.2)
		tickPower = max(tickPower-delta*3.0, 0.0)
	
	if polarFxBackground:
		polarFxBackground.setPower(remap(energyFieldPower, 0, 1, 0.93, 1.1)+tickPower)
		polarFxBackground.position = global_position
		polarFxBackground.setScale(radius*0.1)
		polarFxBackground.rotation = snapped(wrapf(polarFxBackground.rotation+delta, 0, TAU), TAU*0.2)


func playHitSound(target:Node2D):
	if canShowArc:
		tickPower += 0.15
		canShowArc = false
		$ArcShowTimer.wait_time = randf_range(0.15, 0.23)
		$ArcShowTimer.start()
		var attackPosition = target.getCenter() + Vector2(1 + randf()*8.0, 0.0).rotated(randf()*TAU)
		arc_group.target = attackPosition
		arc_group.forceCreateArc()
		arc_group_2.target = attackPosition
		arc_group_2.forceCreateArc()
		var sparks = preload("res://content/weapons/tesla/OrbImpactSparks.tscn").instantiate()
		sparks.position = attackPosition
		Level.map.addPixelEffect(sparks)
		
	if canPlayDamageSound:
		tickPower += 0.3
		$TickSoundTimer.wait_time = randf_range(0.3, 0.65)
		$TickSoundTimer.start()
		canPlayDamageSound = false
		$OrbDamageTick.play()

func _on_TickSoundTimer_timeout():
	canPlayDamageSound = true

func _on_ArcShowTimer_timeout():
	canShowArc = true
