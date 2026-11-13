extends SecondaryWeapon

var dist:float

var playSound := false

var externallyDisabled := false
var active := false
var animatingCountdown := 0.0
var totalFireTime:float
var remainingFireTime:float
var remainingCooldown:float

var hitAreaBaseSize:float
var animationSuffix:String = "_1"

var target
var pathProbe: PathFollow2D

var monsterInHitArea := []
const MAX_RANGE = 450

func _ready():
	Style.init(self)
	Data.listen(self, "stunlaser.stunarea", true)
	Data.listen(self, "stunlaser.stage", true)

	$CooldownParticles.emitting = false

func init(cupulaPath:Path2D):
	stop()

	pathProbe = cupulaPath.createPathProbe(self)

	remainingFireTime = Data.of("stunLaser.fireTime")
	totalFireTime = remainingFireTime

	$Sprite2D.play("off" + animationSuffix)

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"stunlaser.stunarea":
			hitAreaBaseSize = newValue
			if newValue > 0.0:
				$BeamHitArea/CollisionShape2D.shape.radius = newValue
				$BeamHitArea/CollisionShape2D.disabled = false
				$BeamHitArea.monitoring = true
				$BeamHitArea/Sprite2D.visible = true
			else:
				$BeamHitArea/CollisionShape2D.disabled = true
				$BeamHitArea.monitoring = false
				$BeamHitArea/Sprite2D.visible = false
		"stunlaser.stage":
			$LaserBeam.width = newValue
			$LaserBeam.setStage(newValue)
			animationSuffix = "_" + str(newValue)
			match newValue:
				1: $Cannon.texture = preload("res://content/gadgets/stunLaser/cannont1.png")
				2: $Cannon.texture = preload("res://content/gadgets/stunLaser/cannont2.png")
				3: $Cannon.texture = preload("res://content/gadgets/stunLaser/cannont3.png")

func serialize()->Dictionary:
	var data = {
		"probeOffset": pathProbe.progress
	}
	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	return data
	
func deserialize(data: Dictionary):
	await GameWorld.savegame_loaded
	
	pathProbe.progress = data["probeOffset"]

func _physics_process(delta):
	if GameWorld.paused or externallyDisabled:
		return
	
	if animatingCountdown > 0.0:
		animatingCountdown -= delta
		return
	
	if playerControlled:
		if remainingCooldown > 0.0:
			remainingCooldown -= delta * 3.0
			$CooldownParticles.rotation = -rotation
			$Sprite2D.play("cooldown" + animationSuffix)
			if remainingCooldown <= 0.0:
				finishCooldown()
			if not Data.of("stunLaser.trackingInCooldown"):
				return

		if not active:
			return

		if firing and remainingCooldown <= 0:
			var c = $RayCast2D.get_collider()
			if $RayCast2D.enabled and remainingFireTime > 0 and c and is_instance_valid(c) and canTarget(c):
				target = c
			else:
				target = null
				$BeamHitArea.visible = false

			fire(delta)
			handleFiring(delta)
			updateCannonFraction()
		else:
			stopFire()
			remainingFireTime = min(remainingFireTime + delta, Data.of("stunLaser.fireTime"))
			if remainingCooldown <= 0.0:
				updateCannonFraction()

		if move.x != 0.0:
			var baseMoveSpeed = Data.of("stunLaser.speed") * 0.5
			if not $MoveSound.playing:
				$MoveSound.play()
			acceleration = clamp(acceleration + (5.0 - 3.5 * baseMoveSpeed) * delta, 0.0, 1.0)
			if Options.useGamepad:
				currentSpeed = baseMoveSpeed * pow(abs(move.x), 2.0) * sign(move.x)
			else:
				currentSpeed += (baseMoveSpeed * move.x - currentSpeed) * delta * 8.0 * acceleration
			pathProbe.moveBy(currentSpeed * delta)
			$Sprite2D.play("move" + animationSuffix)
			$MoveSound.play()
		else:
			if remainingCooldown > 0.0:
				$Sprite2D.play("cooldown" + animationSuffix)
			else:
				$Sprite2D.play("idle" + animationSuffix)

			$MoveSound.stop()
			currentSpeed = 0
			acceleration = 0
	else:
		if active:
			if not Data.of("monsters.wavepresent") or (not Keepers.oneInsideStation() and not Data.of("stunLaser.autonomy")):
				stop()
				return
		else:
			if Data.of("monsters.wavepresent") and (Keepers.oneInsideStation() or Data.of("stunLaser.autonomy")):
				start()
				return

		if not active:
			return

		if remainingCooldown > 0.0:
			$CooldownParticles.rotation = -rotation
			remainingCooldown -= delta
			if remainingCooldown <= 0.0:
				finishCooldown()
				return
			elif not Data.of("stunLaser.trackingInCooldown"):
				return

		updateCannonFraction()
		if firing and handleFiring(delta):
			return

		if not is_instance_valid(target):
			target = null

		if not target and not firing and (remainingCooldown <= 0 or Data.of("stunLaser.trackingInCooldown")):
			findTarget()
			return

		if target and (remainingCooldown <= 0 or Data.of("stunLaser.trackingInCooldown")):
			#TODO :Attempt to call function 'getShootPosition' in base 'null instance' on a null instance.
			# added is_instance_valid check in target find

			var d:Vector2 = target.getCenter() - $BasePosition.global_position
			dist = d.angle() - (rotation-CONST.PI_HALF)
			if dist > PI:
				dist -= 2*PI
			elif dist < -PI:
				dist += 2*PI

			if rotation > 0.8 and dist > CONST.PI_HALF:
				dist -= 2 * PI
			elif rotation < -0.8 and dist < - CONST.PI_HALF:
				dist += 2 * PI

			dist = clamp(dist, -0.4, 0.4)
			if abs(dist) > 0.01:
				pathProbe.moveBy(delta * dist * Data.of("stunLaser.speed"))
				$Sprite2D.play("move" + animationSuffix)
				$MoveSound.play()
		else:
			$MoveSound.stop()

		var c = $RayCast2D.get_collider()
		if $RayCast2D.enabled and remainingFireTime > 0:
			if c and is_instance_valid(c):
				if c and canTarget(c):
					if c != target:
						setTarget(c)
					fire(delta)
				else:
					stopFire()

func handleFiring(delta:float) -> bool:
	remainingFireTime -= delta

	if remainingFireTime <= 0.0:
		stopFire()
		remainingCooldown = Data.of("stunLaser.cooldown")
		$Sprite2D.play("cooldown" + animationSuffix)
		$CooldownParticles.emitting = true
		return true
	return false

func updateCannonFraction():
	var fraction = floor(min(11, 12.0 * remainingFireTime / totalFireTime))
	setCannonFraction(fraction)

func finishCooldown():
	$CooldownParticles.emitting = false
	remainingFireTime = Data.of("stunLaser.fireTime")
	if active:
		$ActivateSound.play()
		$Tween.stop_all()
		$Tween.remove_all()
		$Tween.interpolate_method(self, "setCannonFraction", 0, 11, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		$Tween.start()
		animatingCountdown = 1.0

func setCannonFraction(fraction:int):
	$Cannon.region_rect.size.y = fraction
	$Cannon.region_rect.position.y = 0
	$Cannon.offset.y = 11 - fraction

func start():
	$Sprite2D.play("start" + animationSuffix)
	animatingCountdown = 0.7
	active = true
	if remainingCooldown <= 0:
		$Tween.stop_all()
		$Tween.remove_all()
		$Tween.interpolate_method(self, "setCannonFraction", 0, 11, 0.7, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		$Tween.start()
		$ActivateSound.play()

func stop():
	stopFire()
	$Sprite2D.play("shutdown" + animationSuffix)
	active = false
	target = null
	var time = max(0.1, $Cannon.region_rect.size.y / 11.0)
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_method(self, "setCannonFraction", $Cannon.region_rect.size.y, 0, time, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$Tween.interpolate_callback(self, time, "set", "animating", false)
	$Tween.start()
	animatingCountdown = time

func fire(delta:float):
	var laserEndPos:Vector2

	if target:
		var collisionPoint = $RayCast2D.get_collision_point()
		laserEndPos = Vector2(0,-1) * ((collisionPoint - global_position).length() + 8)

		var stunStrength = Data.of("stunLaser.stunstrength")
		target.hit("stunlaser", 0, stunStrength)

		if $BeamHitArea.monitoring:
			$BeamHitArea.rotation = -rotation
			if not $BeamHitArea.visible:
				$BeamHitArea.visible = true
				$StunAreaSound.play()
				$BeamHitArea.position = laserEndPos
			else:
				# smoothing of beamhitareamovement
				var beamdelta = laserEndPos - $BeamHitArea.position
				if beamdelta.length() > 30:
					$BeamHitArea.position = laserEndPos
				else:
					$BeamHitArea.position += beamdelta.normalized() * 60 * delta

			var additionalMonsters = (monsterInHitArea.size() - 1)
			var radius = hitAreaBaseSize + additionalMonsters * Data.of("stunLaser.areagrowthpermonster")
			$BeamHitArea/CollisionShape2D.shape.radius = radius
			$BeamHitArea/Sprite2D.material.set_shader_parameter("pixelation_factor", radius * 2)
			$BeamHitArea/Sprite2D.scale = Vector2(1.2, 1.2) / ($BeamHitArea/Sprite2D.texture.get_size() / (radius * 2))
			var areaStunStrength = Data.of("stunLaser.areastunstrength")
			var damage = Data.of("stunLaser.damagepermonster") * additionalMonsters
			if playerControlled and damage > 0:
				damage = (damage + 1) * 3
			for monster in monsterInHitArea:
				monster.hit("stunlaser", damage * delta, stunStrength * areaStunStrength)
				areaStunStrength *= 0.85
	else:
		laserEndPos = Vector2(0,-1) * 600

	$Sprite2D.play("shoot" + animationSuffix)
	$LaserBeam.shootAt(laserEndPos)

	if not firing:
		$FireSound.play()
	firing = true

func stopFire():
	$LaserBeam.stopShooting()
	$BeamHitArea.visible = false
	$StunAreaSound.stop()
	
	if firing:
		$FireSound.stop()
		$StopSound.play()
		firing = false

func canTarget(m):
	return m.alive() \
	and m.stunPriority > 0 \
	and not m.invulnerable \
	and m.canBeHit() \
	#range check, assumes dome at 0,0, don't allows stunning offscreen
	and m.global_position.length() < MAX_RANGE 

func findTarget():
	var closestM
	var minimalAngle := 99.0
	
	var monsters = get_tree().get_nodes_in_group("monster")
	for i in range(1, 5):
		for m in monsters:
			if i != m.stunPriority or not canTarget(m):
				continue
			
			var angle = abs((m.global_position-global_position).angle() - (rotation-CONST.PI_HALF))
			if angle < minimalAngle:
				minimalAngle = angle
				closestM = m
			
		if closestM:
			if closestM != target:
				setTarget(closestM)
			return

func setTarget(m):
	if target:
		target.disconnect("died", Callable(self, "targetDied"))
	target = m
	if not target.is_connected("died", Callable(self, "targetDied")):
		target.connect("died", Callable(self, "targetDied"))

func targetDied():
	target = null
	stopFire()
	findTarget()

func _on_Sprite_animation_finished():
	if $Sprite2D.animation == "start":
		$Cannon.visible = true

func onGameLost():
	externallyDisabled = true
	stop()

func _on_BeamHitArea_area_entered(area):
	if not monsterInHitArea.has(area):
		monsterInHitArea.append(area)

func _on_BeamHitArea_area_exited(area):
	monsterInHitArea.erase(area)

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()
