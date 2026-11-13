extends Node2D

const GRENADE := preload("res://content/weapons/artillery/Grenade.tscn")
const BAND_ZERO_POS := 0.0
const BAND_FULL_STEP := -24.0

@export var gunAimLineColor := Color("#0891B4")

var showcaseMode := false
var move:Vector2
var currentSpeed:float

var bandStep : float = BAND_FULL_STEP
var mortarCooldown:float
var mortarLastFullCooldown := 1.0
var mortarPressedValue:float
var mortarChargeProgression:float
var mortarShotsLeft:int
var mortarInterShotCooldown:float
var mortarChargeDuration := 0.0
var lastRotation := 0.0
var gunPressedValue:float
var shotSoundId := 0

var lockOnGun := false
var lockOnMortar := false

var started := false

@onready var mortarBarrel = $Ball/Joint3D/MortarBarrel
@onready var gunBarrel1 = $Ball/Joint3D/GunBarrel1
@onready var gunBarrel2 = $Ball/Joint3D/GunBarrel2
@onready var band = $"%Band"
@onready var bandMulti = $"%BandMulti"
@onready var cog = $Ball/Cog
@onready var gunAimLine = $"%GunAimLine"
@onready var gunRayCast = $Ball/Joint3D/GunAimLine/GunAimLineRayCast
@onready var mortarAimLine = $"%MortarAimLine"
@onready var laserTarget = $"%LaserTarget"
@onready var laserStart = $"%LaserStart"
@onready var mortarTarget = $"%MortarTargetGroup"
@onready var targetMarker = $"%TargetMarker"
@onready var readySounds := [$Ready, $Ready2, $Ready3, $Ready4, $Ready5]
@onready var reloadSounds := [$ReloadCog, $ReloadCog1, $ReloadCog2, $ReloadCog3, $ReloadCog4, $ReloadCog5]
@onready var reloadSoundsPitch := [
	$ReloadCog.pitch_scale, $ReloadCog1.pitch_scale,
	$ReloadCog2.pitch_scale, $ReloadCog3.pitch_scale,
	$ReloadCog4.pitch_scale, $ReloadCog5.pitch_scale]

@onready var multiBandAmmo := [
	[$Base/Ammoband/BandMulti/AmmoLvl0/Ammo_1_0,
	$Base/Ammoband/BandMulti/AmmoLvl0/Ammo_1_1,
	$Base/Ammoband/BandMulti/AmmoLvl0/Ammo_1_2,
	$Base/Ammoband/BandMulti/AmmoLvl0/Ammo_1_3,],
	[$Base/Ammoband/BandMulti/AmmoLvl0/Ammo_2_0,
	$Base/Ammoband/BandMulti/AmmoLvl0/Ammo_2_1,
	$Base/Ammoband/BandMulti/AmmoLvl0/Ammo_2_2,
	$Base/Ammoband/BandMulti/AmmoLvl0/Ammo_2_3,]
]

func _ready():
	Data.listen(self, "artillery.mortaraimline")
	Data.listen(self, "artillery.gunaimline")
	Data.listen(self, "artillery.grenadereloadspeed")
	Data.listen(self, "artillery.grenades")
	Data.listen(self, "artillery.cannonbarrelsize")
	Data.listen(self, "artillery.machinegunbarrelsize")
	Data.listen(self, "artillery.machinegunbarrels", true)
	Style.init(self)
	initialReset()
	
	Level.addTutorial(self, "artillery_intro")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"artillery.machinegunbarrels":
			if newValue > 1:
				$Ball/Joint3D/GunBarrel2.visible = true
				$"%GunAimLine".position = Vector2(0, -14)
			else:
				$Ball/Joint3D/GunBarrel2.visible = false
				$"%GunAimLine".position.x = -9
		"artillery.grenadereloadspeed":
			band.position.y = 0
			if newValue <= 1.0:
				bandStep = BAND_FULL_STEP / 4.0
				$"%AmmoLvl2".show()
				$"%AmmoLvl1".show()
			elif newValue <= 2.0:
				bandStep = BAND_FULL_STEP / 2.0
				$"%AmmoLvl2".hide()
				$"%AmmoLvl1".show()
			else:
				bandStep = BAND_FULL_STEP
				$"%AmmoLvl1".hide()
				$"%AmmoLvl2".hide()
		"artillery.grenades":
			if newValue > 1:
				$"%Band".hide()
				$"%BandMulti".show()
				bandMulti.position.y = -54
				for i in min(newValue, 3):
					multiBandAmmo[0][i].show()
					multiBandAmmo[1][i].show()
		"artillery.cannonbarrelsize":
			if newValue == 5:
				shotSoundId = 5
				setAmmoSize(2)
				mortarBarrel.setBarrelSize(int(newValue))
			else:
				shotSoundId = newValue
				setAmmoSize(int(newValue))
				mortarBarrel.setBarrelSize(int(newValue))
		"artillery.machinegunbarrelsize":
			gunBarrel1.setBarrelSize(int(newValue))
			gunBarrel2.setBarrelSize(int(newValue))


func init(cupolaPath):
	pass

func inputs(moveValue:Vector2, fireValue:float, specialValue:float):
	if GameWorld.paused or not started:
		return

	mortarPressedValue = fireValue
	gunPressedValue = specialValue

	if Options.useMouseDomeGameplay and not Options.useGamepad and not showcaseMode:
		var ms = get_global_mouse_position()
		var aimVector:Vector2 = ms - $Ball/Joint3D.global_position
		var angleDiff = aimVector.angle() - ($Ball/Joint3D.rotation - CONST.PI_HALF)
		if angleDiff > PI:
			angleDiff -= 2 * PI
		elif angleDiff < -PI:
			angleDiff += 2 * PI

		if aimVector.x < 0 and angleDiff > CONST.PI_HALF:
			angleDiff -= 2 * PI
		elif aimVector.x > 0 and angleDiff < - CONST.PI_HALF:
			angleDiff += 2 * PI

		var newMove = clamp(angleDiff * 20, -1, 1)
		if newMove != 0 and sign(newMove) != sign(move.x):
			# avoid oscillating and overshooting
			currentSpeed = 0
		move.x = newMove
	else:
		move = moveValue

func _physics_process(delta):
	if GameWorld.paused:
		return
	
	if started:
		updateMortarAimLine()
	
	if started and Data.of("artillery.gunaimline"):
		laserTarget.global_rotation = 0
		laserStart.global_rotation = 0
		updateGunAimLine()
	
	if mortarShotsLeft > 0:
		mortarPressedValue = 0 
		gunPressedValue = 0
		mortarInterShotCooldown -= delta
		var shellReload = remap(mortarInterShotCooldown, Data.of("artillery.timeBetweenGrenades"), 0, 0, 1)
		var posYOffset = (BAND_FULL_STEP/4)*(mortarShotsLeft-Data.of("artillery.grenades")+1)
		bandMulti.position.y = remap(ease(shellReload, 2.0), 0, 1, BAND_ZERO_POS, (BAND_FULL_STEP/4)) - posYOffset + (BAND_FULL_STEP/4)
		
		if mortarInterShotCooldown < 0.0:
			if Data.of("artillery.grenades") > 1:
				var isFirstShot = Data.of("artillery.grenades") == mortarShotsLeft
				fireGrenade(true, isFirstShot)
			else:
				fireGrenade(false)
			mortarShotsLeft -= 1
			mortarInterShotCooldown += Data.of("artillery.timeBetweenGrenades")
			if mortarShotsLeft == 0:
				mortarChargeProgression = 0.0
				mortarChargeDuration = 0.0
				mortarInterShotCooldown = 0
	
	var change:float
	
	var maxSpeed = Data.of("artillery.rotationspeed")
	if gunPressedValue != 0:
		maxSpeed = maxSpeed * Data.of("artillery.rotationspeedwhilemachinegun")
	
	if Options.useGamepad:
		currentSpeed = move.x * maxSpeed
	else:
		if move.x == 0:
			change = -currentSpeed * 0.4
		else:
			var strength = 0.1
			if sign(move.x) != sign(currentSpeed):
				# if changing direction, be double fast
				strength *= 2.0
			change = move.x * strength
		
		currentSpeed = clamp(currentSpeed + change, -maxSpeed, maxSpeed)
	var maxRotation = PI * deg_to_rad(Data.of("artillery.maxrotation")) 
	var oldRot = $Ball/Joint3D.rotation
	$Ball/Joint3D.rotation = clamp($Ball/Joint3D.rotation + currentSpeed * delta, -maxRotation, maxRotation)
	cog.rotation = -$Ball/Joint3D.rotation*2
	if abs(change) > 0.05:
		if started:
			lastRotation = $Ball/Joint3D.rotation
		if oldRot != $Ball/Joint3D.rotation:
			if not $AimCog.playing:
				$AimCog.play()
		else:
			$AimCog.stop()
	else:
		$AimCog.stop()
	
	var delay = gunBarrel1.proc(delta, gunPressedValue)
	if gunBarrel2.visible:
		gunBarrel2.proc(delta, gunPressedValue, delay * 0.5)
	
	if mortarCooldown > 0:
		mortarPressedValue = 0
		mortarCooldown -= delta
		var currentReload = remap(mortarCooldown, mortarLastFullCooldown, 0, 0, 1)
		band.position.y = remap(ease(currentReload, 2.0), 0, 1, BAND_ZERO_POS, bandStep)
		if mortarShotsLeft == 0:
			bandMulti.position.y = remap(ease(currentReload, 2.0), 0, 1, -18, BAND_FULL_STEP-24)+(BAND_FULL_STEP/4)
		if mortarCooldown <= 0:
			mortarBarrel.reloadComplete()
			## Stop old Reload Sounds
			for r in reloadSounds:
				r.stop()
			band.position.y = BAND_ZERO_POS
			## Stop old Ready Sounds
			for r in readySounds:
				r.stop()
			readySounds[clamp(shotSoundId, 0, 4)].play()
	
	if mortarCooldown <= 0:
		if mortarPressedValue > 0.0:
			mortarChargeDuration += delta
			if mortarChargeDuration > 0.15:
				mortarChargeProgression = clamp(mortarChargeProgression + delta, 0.0, 1.0)
			if not $MortarChargeSound.playing and mortarChargeProgression < 1.0:
				$MortarChargeSound.play()
			if mortarChargeProgression >= 1.0:
				$MortarChargeSound.stop()
#			$MortarChargeSound.pitch_scale = 0.4 + mortarChargeProgression
		else:
			if mortarChargeDuration > 0.0:
				mortarShotsLeft = Data.of("artillery.grenades")


func updateGunAimLine():
	if gunRayCast.get_collider():
		var collider = gunRayCast.get_collider()
		var dist = gunRayCast.global_position.distance_to(gunRayCast.get_collision_point())
		gunAimLine.points[1].y = -dist
		laserTarget.position.y = -dist
		if collider and collider.is_in_group("monster"):
			collider.aim()
	else:
		gunAimLine.points[1].y = -1000
		laserTarget.position.y = -1000

func updateMortarAimLine():
	if mortarChargeProgression > 0.0 and (mortarPressedValue > 0.0 or mortarShotsLeft > 0):
		mortarAimLine.modulate.a = 1.0
	elif mortarCooldown > 0.0:
		mortarAimLine.modulate.a = 0.0
	else:
		mortarAimLine.modulate.a = 0.6
	var velocity = Vector2(0,-getGrenadeVelocity()).rotated($Ball/Joint3D.rotation)
	var mortarSpawnPoint : Vector2 = mortarBarrel.getSpawnPoint().global_position
	var currentPosition = mortarSpawnPoint - $ShotPredictionPath.global_position
	$ShotPredictionPath.curve.clear_points()
	$ShotPredictionPath.curve.add_point(currentPosition)
	var precision := 0.05
	while true:
		velocity.y += precision * Data.of("artillery.grenadeGravity")
		currentPosition += precision * velocity
		$ShotPredictionPath.curve.add_point(currentPosition)
		if currentPosition.y > 30:
			precision = 0.02
		if currentPosition.y > 60:
			break
	mortarAimLine.clear_points()
	mortarAimLine.points = $ShotPredictionPath.curve.get_baked_points()
	
	# Cast rays along the AimLine curve using the physics server
	# This loop runs in approx 0.15-0.45 milliseconds depending on the
	# length of the aimline
	var space_state = get_world_2d().direct_space_state
	for n in range(mortarAimLine.get_point_count()-1):
		var params: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
		params.from = to_global(mortarAimLine.position + mortarAimLine.get_point_position(n))
		params.to = to_global(mortarAimLine.position + mortarAimLine.get_point_position(n+1))
		params.collision_mask = 16777216
		params.collide_with_areas = true
		params.collide_with_bodies = true
		var c = space_state.intersect_ray(params)
		if c and c.collider:
			mortarTarget.show()
			mortarTarget.global_position = c.position
			targetMarker.rotation = c.normal.angle()+PI/2
			var pointCount = mortarAimLine.get_point_count()
			var pointsToDelete = pointCount-n
			for i in pointsToDelete:
				mortarAimLine.remove_point(pointCount-i-1)
			break
		else:
			mortarTarget.hide()

func fireGrenade(isMultishot:bool=false, isFirstShot:=true):
	InputSystem.shake(80, 0.4, 12, global_position)
	var grenade = GRENADE.instantiate()
	grenade.rotation = $Ball/Joint3D.rotation
	grenade.position = mortarBarrel.getSpawnPoint().global_position
	grenade.fullEffect = isFirstShot
	Level.map.add_child(grenade)
	grenade.fire(getGrenadeVelocity())
	mortarLastFullCooldown = max(0.5, Data.of("artillery.grenadereloadspeed"))
	mortarCooldown = mortarLastFullCooldown
	var shotSound = find_child("ShotSound%s" % str(shotSoundId+1))
	if isFirstShot:
		shotSound.setAdditionalVolume(0.0)
	else:
		shotSound.setAdditionalVolume(-7.0)
	shotSound.play()
	$MortarChargeSound.stop()
	for r in reloadSounds:
		r.stop()
	if Data.of("artillery.grenadeswiftreload"):
		reloadSounds[shotSoundId].pitch_scale = reloadSoundsPitch[shotSoundId]*1.2
	reloadSounds[shotSoundId].play()
	mortarBarrel.shoot(mortarCooldown, isMultishot)
	
	if Data.of("artillery.shotstun"):
		var shockwave = preload("res://content/gadgets/shockwave/Shockwave.tscn").instantiate()
		shockwave.position = %StunShockwaveSource.global_position
		var strength = sqrt(Data.of("artillery.grenadedamage"))
		var stunDuration = strength * 0.1      
		var stunStrength = strength * 0.5
		var stunSize = 30 + strength * 13
		
		shockwave.setup(0, 600, true, 0.0, stunStrength, stunDuration, stunSize)
		Level.map.add_child(shockwave)
			

func getGrenadeVelocity() -> float:
	return Data.of("artillery.grenadeMinimumVelocity") + mortarChargeProgression * Data.of("artillery.grenadeMaximumChargeVelocity")


func setAmmoSize(frame:int=0):
	for ammo in get_tree().get_nodes_in_group("band_ammo"):
		ammo.frame = frame


func initialReset():
	$Ball.position.y = 6
	gunBarrel1.position.x = 0
	gunBarrel2.position.x = 0
	$MortarAimLine.visible = false


func start():
	started = true
	$StationTween.remove_all()
	$StationTween.interpolate_property($Ball, "position:y", $Ball.position.y, -18, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$StationTween.interpolate_property(gunBarrel1, "position:x", gunBarrel1.position.x, -9, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.3)
	$StationTween.interpolate_property(gunBarrel2, "position:x", gunBarrel2.position.x, 9, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.3)
	$StationTween.interpolate_property($Ball/Joint3D, "rotation", $Ball/Joint3D.rotation, lastRotation, 0.5, Tween.TRANS_QUINT, Tween.EASE_OUT, 0.2)
	$StationTween.interpolate_callback($MortarAimLine, 0.5, "set_visible", true)
	if Data.of("artillery.gunaimline"):
		$StationTween.interpolate_callback(gunAimLine, 0.5, "set_visible", true)
	$StationTween.start()
	if mortarCooldown > 0:
		if Data.of("artillery.grenadeswiftreload"):
			reloadSounds[shotSoundId].pitch_scale = reloadSoundsPitch[shotSoundId]*1.2
		reloadSounds[shotSoundId].play()


func stop():
	started = false
	$StationTween.remove_all()
	$StationTween.interpolate_property($Ball, "position:y", $Ball.position.y, 6, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.4)
	$StationTween.interpolate_property($Ball/Joint3D, "rotation", $Ball/Joint3D.rotation, 0, 0.5, Tween.TRANS_QUINT, Tween.EASE_OUT)
	$StationTween.interpolate_property(gunBarrel1, "position:x", gunBarrel1.position.x, 0, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$StationTween.interpolate_property(gunBarrel2, "position:x", gunBarrel2.position.x, 0, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$StationTween.start()
	$AimCog.stop()
	for r in reloadSounds:
		r.stop()
	find_child("GunAimLine").hide()
	$MortarAimLine.visible = false
	move *= 0.0

func getFireName():
	return "level.station.battle.navbar.artilleryshoot"

func getSpecialName():
	return "level.station.battle.navbar.artilleryflak"

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()

func updateStyleColor():
	$"%GunAimLine".modulate = Style.mapColor(gunAimLineColor)
	$"%MortarAimLine".modulate = Style.mapColor(gunAimLineColor)
