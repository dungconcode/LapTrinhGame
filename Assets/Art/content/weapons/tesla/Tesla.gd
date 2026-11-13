extends Node2D

const activationHeight := -165.0

var showcaseMode := false
var move:Vector2
var maxCharge:float
var shotCharge:float
var isCharging:bool
var clampedShotCharge:float
var beamSlowdown:float
var logicDelay:float
var perfectCooldownShotWindow:Vector2
var perfectCooldownShotVisualization:Vector2
var fireValue:float
var specialValue:float
var reloadedSoundPlayed:bool

var started:bool

var ringsIdleSpeed := 0.0
var chargeValue := 0.0
var remaingingQuickshots := 0
var perfectTimingEnabled:bool = false

@onready var bgScene = $"%BGScene"
@onready var fgScene = $"%FGScene"
@onready var reticle = $Reticle
@onready var arcAim = $"%ArcAim"
@onready var perfectHitArc = $PerfectHitArc
@onready var arcShoot = $"%ShootAim"
@onready var crystalCenter = $"%CrystalCenter"
@onready var cap = $Cap
@onready var ringSounds = $RingSounds


func init(cupulaPath:Path2D):
	Style.init(self)
	maxCharge = Data.of("tesla.maxcharge")

	reticle.showcaseMode = showcaseMode

	Data.listen(self, "tesla.perfecttimingwindow", true)
	Data.listen(self, "tesla.maxcharge", true)
	Data.listen(self, "tesla.ringIdleSpeed", true)
	
	Level.addTutorial(self, "tesla_intro")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"tesla.perfecttimingwindow":
			# for coyote time
			perfectCooldownShotWindow = Vector2(-newValue * 0.3, newValue * 1.3)
			perfectCooldownShotVisualization = Vector2(0, newValue)
			perfectTimingEnabled = newValue > 0.0
		"tesla.maxcharge":
			maxCharge = newValue
		"tesla.ringidlespeed":
			ringsIdleSpeed = newValue

func _ready():
	bgScene.mainScene = self
	fgScene.mainScene = self
	get_parent().get_parent().get_node("Station").connect("station_hit_top", Callable(self, "stationHitTop"))
	%TrafoAnim1.play("default")
	%TrafoAnim2.play("default")
	connect("tree_exited", Callable(reticle, "queue_free"))


func inputs(moveValue:Vector2, fireValue:float, specialValue:float):
	if GameWorld.paused or not started:
		return

	self.move = moveValue
	self.fireValue = fireValue
	self.specialValue = specialValue


func _physics_process(delta):
	updateCharge(delta)
	updateCrystalOscillation(delta)
	if GameWorld.paused:
		return
	
	applyDamageFromOrbs(delta)
	
	if not started:
		return
	
	var chargePerSecond = float(Data.of("tesla.chargepersecond"))
	
	updateArcs(delta)
	
	var filling = clamp(shotCharge / maxCharge, 0.0, 1.0)
	bgScene.targetSpeed = lerp(bgScene.targetSpeed, max(filling*8, ringsIdleSpeed), delta*2.0)
	fgScene.targetSpeed = lerp(fgScene.targetSpeed, max(filling*8, ringsIdleSpeed), delta*2.0)
	bgScene.power = filling
	fgScene.power = filling
	
	var perfectTiming:bool = false
	if perfectTimingEnabled:
		reticle.enablePerfectTiming()
		perfectTiming = perfectCooldownShotWindow.x + maxCharge < shotCharge and perfectCooldownShotWindow.y + maxCharge > shotCharge
		var showPerfectTiming = perfectCooldownShotVisualization.x + maxCharge < shotCharge and perfectCooldownShotVisualization.y + maxCharge > shotCharge
		if showPerfectTiming:
			$SingleShotSounds/QuickReloadWindow.startIfNotPlaying()
		reticle.setPerfect(showPerfectTiming)
		$"%PerfectSparks".emitting = showPerfectTiming
		$"%PerfectStatic".emitting = showPerfectTiming
	
	if shotCharge >= maxCharge and not perfectTiming and not reloadedSoundPlayed:
		$SingleShotSounds/Reloaded.play()
		reloadedSoundPlayed = true
	
	var canShoot = perfectTiming or shotCharge >= maxCharge
	if fireValue > 0.0:
		reticle.charge(true)
		# let charge run over maxCharge so the perfect timing window can be handled with coyote time
		shotCharge = shotCharge + chargePerSecond * delta
		isCharging = true
	else:
		if canShoot:
			shootSingle(perfectTiming, false)
			isCharging = false
		else:
			shotFirstArc = false
			reticle.charge(false)
			
			if isCharging and shotCharge <= 0.15 and remaingingQuickshots > 0:
				shotCharge = 0
				shootSingle(false, true)
			
			# if releasing, shotcharge might be larger than maxcharge, so it should jump down to maxcharge
			shotCharge = clamp(shotCharge - chargePerSecond * delta * 2, 0, maxCharge)
			isCharging = false
	
	clampedShotCharge = clamp(shotCharge, 0.0, 1.0)
	ringSounds.shotCharge = clampedShotCharge
	arcAim.target = reticle.getShotPosition()
	arcAim.showEndFork = clampedShotCharge >= 1.0
	
	# Reticle Controls
	if crystalCenter.global_position.y < activationHeight:
		if not reticle.active:
			reticle.activate()
			arcGroupL.forceCreateArc()
			arcGroupR.forceCreateArc()
	reticle.move(move, delta)
	reticle.shotCharge = clampedShotCharge

func applyDamageFromOrbs(delta:float):
	# phew, this shit's a bit tricky.
	# The goal here is that a monster can only be damaged by one electro orb, as otherwise a layering of orbs cannot be balanced.
	# To achieve this:
	# 1. check for each monster, by which orbs it might be hit by
	var thundersByMonster := {}
	for thunder in get_tree().get_nodes_in_group("tesla-thunder"):
		var monsters = thunder.getMonstersToDamage()
		for m in monsters:
			if m.canBeHit() and m.alive() and not m.invulnerable:
				var orbs = thundersByMonster.get(m, [])
				orbs.append(thunder)
				thundersByMonster[m] = orbs
	
	# 2. take a random orb for each monster as the one that does hit it and remember that1
	var monstersByThunder := {}
	for monster in thundersByMonster:
		var thunders = thundersByMonster.get(monster, [])
		if thunders.size() > 0:
			var thunder = thunders[randi() % thunders.size()]
			var monsters = monstersByThunder.get(thunder, [])
			monsters.append(monster)
			monstersByThunder[thunder] = monsters
	
	# 3. finally, each orb has to apply the damage and play the right effects
	var stunStrength = Data.of("tesla.persistencestunstrength")
	for thunder in monstersByThunder:
		thunder.damageMonsters(monstersByThunder[thunder], delta, stunStrength)
	#4. profit

var crystalOscillationT1 := 0.0
var crystalOscillationT2 := 0.0
func updateCrystalOscillation(delta):
	crystalOscillationT1 = wrapf(crystalOscillationT1+delta*20, 0, TAU)
	crystalOscillationT2 = wrapf(crystalOscillationT2+delta*40, 0, TAU)
	$"%CrystalSprites".position = Vector2.RIGHT.rotated(crystalOscillationT1)*sin(crystalOscillationT2)*1.3*ease(chargeBuffer, 4.0)


var shotFirstArc := false
func updateArcs(delta):
	# Put the particle at the height of the 3D Ring
	$"%CrystalParticle".position.y = $"%FGScene".getRingHeight()-64-25
	
	# Aim the beak arcs to the 3D Ring
	for c in arcL.get_children():
		c.target = Vector2(randf_range(-35, 35)*clampedShotCharge, $"%FGScene".getRingHeight()-275-25)
		c.position = Vector2(randf_range(-15, 15), 0).rotated(0.35)
	for c in arcR.get_children():
		c.target = Vector2(randf_range(-35, 35)*clampedShotCharge, $"%FGScene".getRingHeight()-275-25)
		c.position = Vector2(randf_range(-15, 15), 0).rotated(-0.35)
	
	# Activate the Aiming Arc if the crystal is in the active position
	#arcAim.visible = crystalCenter.global_position.y < activationHeight
	
#	var arcInterval = range_lerp(clampedShotCharge, 0, 1, 0.5, 0)
#	var arcMod = range_lerp(ease(clampedShotCharge, 0.4), 0, 1, 1.0, 0.4)
	
	if fireValue > 0 and not shotFirstArc:
		shotFirstArc = true
		#arcAim.forceCreateArc()
		arcGroupL.forceCreateArc()
		arcGroupR.forceCreateArc()
	#arcAim.visible = fireValue > 0.0
	#arcAim.randomInterval = arcInterval
	#arcAim.spawnInterval = range_lerp(clampedShotCharge, 0, 1, 0.25, 0.1)
	#arcAim.modulate.a = arcMod

func start():
	$"%StationLight".show()
	ringSounds.start()
	started = true

func stationHitTop():
	match int(Data.of("tesla.powervfx")):
		4, 3:
			$SingleShotSounds/RingStart3.play()
		2, 1:
			$SingleShotSounds/RingStart2.play()
		_:
			$SingleShotSounds/RingStart1.play()

func stop():
	started = false
	$"%StationLight".hide()
	arcAim.hide()
	reticle.deactivate()
	reticle.shotCharge = 0.0
	shotCharge = 0.0
	clampedShotCharge = 0.0
	ringSounds.stop()


var chargePulse := 0.0
var oldCharge := 0.0
var chargeBuffer := 0.0

@onready var arcL = $"%ArcL"
@onready var arcR = $"%ArcR"
@onready var arcGroupL = $"%ArcGroupL"
@onready var arcGroupR = $"%ArcGroupR"
@onready var trafoParticle1 = $"%TrafoParticle1"
@onready var trafoParticle2 = $"%TrafoParticle2"

func updateCharge(delta:float):
	var holdingFire : bool = fireValue > 0
	arcL.visible = holdingFire
	arcR.visible = holdingFire
	arcGroupL.randomInterval = remap(clampedShotCharge, 0, 1, 1.9, 0.1)
	arcGroupR.randomInterval = remap(clampedShotCharge, 0, 1, 1.9, 0.1)
	 
	$"%SchnabelParticleL".emitting = holdingFire
	$"%SchnabelParticleR".emitting = holdingFire
	
	chargePulse = wrapf(chargePulse+delta*clampedShotCharge*4, 0, 1)
	var mod = (sin(ease(chargePulse, 5)*TAU)+2)*0.5+0.2
	var modColor = Color(mod, mod, mod, clampedShotCharge)
	
	$"%TeslaCrystalAdditive".modulate.a = lerp(0.12, 1.0, clampedShotCharge)
	$"%CrystalPolarEffect".setPower(ease(clampedShotCharge, 3.6)*0.8)
	
	%TrafoAnim1.modulate = modColor
	%TrafoAnim2.modulate = modColor
	%TrafoAnim1.speed_scale = clampedShotCharge*2.0+0.3
	%TrafoAnim2.speed_scale = clampedShotCharge*2.0+0.3
	trafoParticle1.emitting = holdingFire
	trafoParticle1.scale = Vector2.ONE * clampedShotCharge
	trafoParticle2.emitting = holdingFire
	trafoParticle2.scale = Vector2.ONE * clampedShotCharge
	
	$"%CrystalParticle".emitting = clampedShotCharge > 0.99
	$"%TeslaCrystalParticle".emitting = clampedShotCharge > 0.99
	$"%CrystalSprites".modulate = lerp(Color.WHITE, Color(2,2,2,1.0), ease(chargeBuffer, 2.0))
	
	# Backside "Trafo"
	$"%ShaderTrafo".visible = chargeBuffer > 0.0
	$"%ShaderTrafo".material.set_shader_parameter("power", ease(clampedShotCharge, 2))
	if shotCharge > oldCharge:
		chargeBuffer = lerp(chargeBuffer, ease(clampedShotCharge, 20.2), delta*12)
	else:
		chargeBuffer = lerp(chargeBuffer, 0.0, delta*4)
	$"%ShaderTrafo".material.set_shader_parameter("fill", chargeBuffer)
	$"%StationLight".modulate.a = chargeBuffer
	oldCharge = shotCharge
	if holdingFire:
		trafoParticle1.self_modulate = modColor
		trafoParticle2.self_modulate = modColor

func getFireName():
	return "level.station.battle.navbar.shoot"

func getSpecialName():
	return ""

func shootSingle(perfectTiming:bool, quickshot:bool):
	var powervfx = Data.of("tesla.powervfx")
	var shotPosition = reticle.getShotPosition()
	var newImpactSound = preload("res://content/weapons/tesla/sounds/TeslaShotSound.tscn").instantiate()
	Level.viewports.addElement(newImpactSound)
	newImpactSound.play(powervfx, shotPosition, quickshot)
	
	var newImpact = preload("res://content/weapons/tesla/TeslaImpact.tscn").instantiate()
	newImpact.position = shotPosition
	newImpact.setPower(powervfx)
	Level.map.addPixelEffect(newImpact)
	
	arcShoot.target = shotPosition
	var arcDuration = remap(float(powervfx), 0.0, 4.0, 0.7, 2.0)
	arcShoot.forkSpawnArea = Vector2(4,4) * arcDuration
	$Tween.interpolate_method(self, "controlShootArc", 1, 0, arcDuration, Tween.TRANS_SINE, Tween.EASE_OUT)
	
	var newShot = preload("res://content/weapons/tesla/TeslaThunder.tscn").instantiate()
	newShot.perfect = perfectTiming
	newShot.global_position = shotPosition
	
	var radius = Data.of("tesla.radius")
	var baseDamage = Data.of("tesla.damage")
	var damage = baseDamage
	var strength = Data.of("tesla.persistance")
	if perfectTiming:
		perfectHitArc.target = shotPosition
		perfectHitArc.global_position = Vector2(shotPosition.x, -480.0)
		$Tween.interpolate_method(self, "controlPerfectShootArc", 1, 0, arcDuration*0.6, Tween.TRANS_SINE, Tween.EASE_OUT)
		var mult = Data.of("tesla.perfecttimingmultiplier")
		damage *= mult
		strength *= mult
		match int(Data.of("tesla.perfecttimingstage")):
			1:
				$SingleShotSounds/QuickReloadSuccess1.play()
			2:
				$SingleShotSounds/QuickReloadSuccess2.play()
			3:
				$SingleShotSounds/QuickReloadSuccess3.play()
	$Tween.start()
	shotCharge = 0
	reloadedSoundPlayed = false
	
	reticle.shoot()
	
	if quickshot:
		strength = 0.0
		damage *= Data.of("tesla.quickshotstrength")
	elif Data.of("tesla.nurture"):
		var overlappingOrb = reticle.getClosestOverlappingOrb()
		if overlappingOrb:
			$SingleShotSounds/NurtureHitSound.play()
			overlappingOrb.strengthen(strength, reticle.global_position)
			strength = 0.0
	
	Level.viewports.addElement(newShot)
	newShot.start(damage, radius, strength)
	
	if quickshot:
		remaingingQuickshots = 0
		reticle.setRemainingQuickshots(0)
	else:
		if Data.of("tesla.quickshotstrength") > 0.0:
			remaingingQuickshots = 1
			reticle.setRemainingQuickshots(remaingingQuickshots)

func controlShootArc(v:float):
	arcShoot.visible = v >= 0.05
	arcShoot.position = (Vector2.RIGHT*float(Data.of("tesla.powervfx"))*2.0).rotated(randf()*TAU)
	var dir = sign(global_position.x - arcShoot.target.x)
	arcShoot.baseCurvature = remap(v, 1.0, 0.0, 0.0, 0.8) * dir
	arcShoot.spawnInterval = remap(ease(v, 0.5), 1.0, 0.0, 0.01, 0.2)
	arcShoot.arcWildness = remap(v, 1.0, 0.0, 0.0, 20.0)
	arcShoot.modulate = lerp(Color(2,2,2,1), Color(1,1,1,1), ease(v, 1.2))
	arcShoot.impactRadius = remap(ease(v, 0.3), 1.0, 0.0, 4.0, 30.0)


func controlPerfectShootArc(v:float):
	perfectHitArc.visible = v >= 0.05
	perfectHitArc.spawnInterval = remap(ease(v, 0.5), 1.0, 0.0, 0.01, 0.2)
	perfectHitArc.arcWildness = remap(v, 1.0, 0.0, 0.0, 20.0)
	perfectHitArc.modulate = lerp(Color(2,2,2,1), Color(1,1,1,1), ease(v, 1.2))
	perfectHitArc.impactRadius = remap(ease(v, 0.3), 1.0, 0.0, 4.0, 30.0)
