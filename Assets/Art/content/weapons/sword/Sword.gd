extends Node2D

var showcaseMode := false
var move:Vector2
var fireValue:float
var specialValue:float
var speed := 0.0
var bladeExtension := 0.0
var extendProgress := 0.0

# after the sword bounced, don't immediately brake it down again
var brakeCooldownAfterBounce := 0.0

var extendPause := 0.0
var maxExtension := 0.0
var power := 0.0
var cooldown := 0.0
var maxCooldown := 0.0
var maxFilling := 0
var fillingY := 0
var extendRotation := 0.0
var remainingPierceDamage := 0
var extending := false
var javelinShot := false
var javelinCharge := 0.0
var javelinCharging := false
var autoAimTarget
var retracting := false
var active := false
var arrowUnlocked := false
var bladeSuffix := "_0"
var additionalBreakFromMouse := 0.0

var hitMonsters := []
var piercedMonsters := {}

var pathProbe

const bladeBasePos := Vector2(0, -4)
const bladeTrailOffset := Vector2(0.0, 2.0)
var finnPosition := Vector2()

@onready var AimLine = $Blade/AimLine
@onready var AimRayCast = $Blade/RayCast2D
@onready var BladeCollisionShape = $Blade/HitArea/BladeCollisionShape

const javelinMaxCharge := 0.6

const Impact = preload("res://content/weapons/sword/Impact.tscn")

var baseMoveVolume:float
var followBladeCollisionShapes := []
var lastHitAreaPosition:Vector2


func init(cupulaPath:Path2D):
	stop()
	$BladeTrail.default_color = Style.STRUCT_BRIGHT
	$Blade/Sprite2D.play("init"+bladeSuffix)
	$Blade/Sparks.pause()
	$Base/BaseEffect.play("empty")
	lastHitAreaPosition = $Blade/HitArea.global_position
	for _i in range(0,4):
		var dup = BladeCollisionShape.duplicate()
		$Blade/HitArea.add_child(dup)
		followBladeCollisionShapes.append(dup)
	
	baseMoveVolume = $MoveSound.volume_db
	
	AimLine.visible = false
	AimRayCast.enabled = false
	$Blade/Bombtip.visible = false
	hideArrow()
	
	pathProbe = cupulaPath.createPathProbe(self)
	
	Data.listen(self, "sword.blade", true)
	Data.listen(self, "sword.reflection", true)
	Data.listen(self, "sword.stabArrowHead", true)
	Data.listen(self, "sword.javelin", true)
	Data.listen(self, "sword.electricDamage")
	updateFilling()
	Style.init(self)
	
	Level.addTutorial(self, "sword_intro")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"sword.electricDamage":
			if newValue > 0:
				$Blade/Sparks.play("idle1")
		"sword.reflection":
			setBase(newValue)
		"sword.blade":
			bladeSuffix = "_"+str(newValue)
			match int(newValue):
				0:
					setBladeDimensions(Vector2(3.5, 13), Vector2(0, -15))
					fillingY = -20
					maxFilling = 24
					finnPosition.x = -5.5
					finnPosition.y = -16
					find_child("Filling").position = Vector2(-1.5, fillingY)
					find_child("Filling").region_rect.size.x = 3
					find_child("Filling").texture = preload("res://content/weapons/sword/blade_small_filling_cooldown.png")
				1:
					setBladeDimensions(Vector2(4.5, 17), Vector2(0, -19))
					fillingY = -28
					maxFilling = 32
					finnPosition.x = -6.5
					finnPosition.y = -23
					find_child("Filling").position = Vector2(-1.5, fillingY)
					find_child("Filling").region_rect.size.x = 3
					find_child("Filling").texture = preload("res://content/weapons/sword/blade_middle_filling_cooldown.png")
					$BladeTrail.width = 14
				2:
					setBladeDimensions(Vector2(5.5, 21.5), Vector2(0, -23.5))
					fillingY = -33
					maxFilling = 41
					finnPosition.x = -5.5
					finnPosition.y = -25
					find_child("Filling").position = Vector2(-2.5, fillingY)
					find_child("Filling").region_rect.size.x = 5
					find_child("Filling").texture = preload("res://content/weapons/sword/blade_needl_filling_cooldown.png")
					$BladeTrail.width = 14
				3:
					setBladeDimensions(Vector2(5.5, 21), Vector2(0, -23))
					fillingY = -37
					maxFilling = 41
					finnPosition.x = -7.5
					finnPosition.y = -30
					find_child("Filling").position = Vector2(-2.5, fillingY)
					find_child("Filling").region_rect.size.x = 5
					find_child("Filling").texture = preload("res://content/weapons/sword/blade_big_filling_cooldown.png")
					$BladeTrail.width = 14
				4:
					setBladeDimensions(Vector2(6.5, 24), Vector2(0, -26))
					fillingY = -43
					maxFilling = 47
					finnPosition.x = -8.5
					finnPosition.y = -36
					find_child("Filling").position = Vector2(-2.5, fillingY)
					find_child("Filling").region_rect.size.x = 5
					find_child("Filling").texture = preload("res://content/weapons/sword/blade_bfs_filling_cooldown.png")
					$BladeTrail.width = 21
				5:
					setBladeDimensions(Vector2(4, 26), Vector2(0, -29))
					fillingY = -38
					maxFilling = 42
					finnPosition.x = -4.5
					finnPosition.y = -35
					find_child("Filling").position = Vector2(-2.5, fillingY)
					find_child("Filling").region_rect.size.x = 5
					find_child("Filling").texture = preload("res://content/weapons/sword/blade_bfn_filling_cooldown.png")
					$BladeTrail.width = 21
			updateFinns(Data.of("sword.stabarrowhead"))
		"sword.stabarrowhead":
			updateFinns(newValue)

func setBladeDimensions(extents:Vector2, pos:Vector2):
	BladeCollisionShape.shape.extents = extents
	BladeCollisionShape.position = pos
	for shape in followBladeCollisionShapes:
		shape.shape.extents = extents
		shape.position = pos

func updateFinns(stage:int):
	if stage > 0:
		$Blade/ArrowLeft.frame = stage - 1
		$Blade/ArrowRight.frame = stage - 1
		$Blade/ArrowLeft.position = finnPosition
		var width = 1-finnPosition.x
		$Blade/ArrowRight.position.x = width
		$Blade/ArrowRight.position.y = finnPosition.y
		$Blade/HitArea/ArrowHead.position.y = finnPosition.y - (3 - stage) * 3 - $Blade/HitArea/ArrowHead.shape.extents.y * 0.5
		$Blade/HitArea/ArrowHead.shape.extents.x = BladeCollisionShape.shape.extents.x + stage * 2 + (2 if stage == 3 else 0) 
		arrowUnlocked = true
	else:
		arrowUnlocked = false

func showArrow():
	$Blade/HitArea/ArrowHead.disabled = false
	$Blade/ArrowLeft.visible = true
	$Blade/ArrowRight.visible = true

func hideArrow():
	$Blade/HitArea/ArrowHead.disabled = true
	$Blade/ArrowLeft.visible = false
	$Blade/ArrowRight.visible = false

func inputs(moveValue:Vector2, fireValue:float, specialValue:float):
	if GameWorld.paused or not active:
		return

	self.fireValue = fireValue
	self.specialValue = specialValue

	additionalBreakFromMouse = 0
	if Options.useMouseDomeGameplay and not Options.useGamepad and not showcaseMode:
		if extending or (javelinCharge >= javelinMaxCharge and Options.swordSliceWithMouse):
			var aimVector = $Blade.get_local_mouse_position()
			if aimVector.length() > 0:
				var dot = aimVector.normalized().dot(Vector2.RIGHT)
				var newMove = clamp(dot * 1.4, -1, 1) # let it turn a bit sharper
				move.x = newMove
				additionalBreakFromMouse = 5
		elif Options.swordSliceWithMouse:
			var aimVector:Vector2 = get_global_mouse_position() - global_position
			var angleDiff = aimVector.angle() - (rotation - CONST.PI_HALF)
			if angleDiff > PI:
				angleDiff -= 2 * PI
			elif angleDiff < -PI:
				angleDiff += 2 * PI

			if aimVector.x < 0 and angleDiff > CONST.PI_HALF:
				angleDiff -= 2 * PI
			elif aimVector.x > 0 and angleDiff < - CONST.PI_HALF:
				angleDiff += 2 * PI

			var newMove = clamp(angleDiff, -1, 1)
			if newMove != 0 and sign(newMove) != sign(move.x):
				# avoid oscillating and overshooting
				speed = 0
			move.x = newMove
			additionalBreakFromMouse = 5
		else:
			move = moveValue
	else:
		move = moveValue

func _physics_process(delta):
	if GameWorld.paused or GameWorld.lost:
		return
	
	if GameWorld.devMode:
		if Input.is_action_just_pressed("num1"):
			Data.apply("sword.blade", Data.of("sword.blade")+1)
			$Blade/Sprite2D.play("cooldown"+bladeSuffix)
			
		if Input.is_action_just_pressed("num2"):
			Data.apply("sword.reflection", Data.of("sword.reflection")+1)

	var brake:float = max(1.0, Data.of("sword.brake"))
	if additionalBreakFromMouse > 1.0:
		brake = (brake + additionalBreakFromMouse) * additionalBreakFromMouse

	var sliceAcceleration:float = max(0.3, Data.of("sword.sliceAcceleration"))
	if brakeCooldownAfterBounce > 0.0:
		brake = 0.0
		sliceAcceleration *= min(1.0, brakeCooldownAfterBounce / 0.1)
		brakeCooldownAfterBounce -= delta
	
	# normal move code
	if move.x == 0:
		$MoveSound.volume_db = baseMoveVolume - 6
		speed = speed - speed * brake * delta
		power = max(power - delta * 4.0, 0.0)
	else:
		$MoveSound.volume_db = baseMoveVolume
		power = min(power + delta * 4.0, 1.0)
		if bladeExtension == 0.0:
			var change = sliceAcceleration * move.x * power * (1.0 - 0.5 * javelinCharge)
			if sign(change) != sign(speed):
				speed = speed - speed * brake * delta
			speed = clamp( speed + change * delta, -3, 3)
	
	if cooldown > 0.0 and not retracting:
		cooldown -= delta
		if not javelinShot and not $RechargeSound.playing:
			var baseCooldown = Data.of("sword.stabCooldown")
			var relativeCooldown = (baseCooldown - cooldown) / baseCooldown
			$RechargeSound.setAdditionalPitch(1 + relativeCooldown * 3)
			$RechargeSound.play()
		
		if cooldown <= 0.0:
			if active:
				if javelinShot: 
					$Blade/Sprite2D.play("on"+bladeSuffix)
				else:
					$Blade/Sprite2D.play("charged"+bladeSuffix)
					$CooldownSound.play()
			else:
				stop()
			cooldown = 0.0
			javelinShot = false
			if active and Data.of("sword.aimline"):
				AimRayCast.enabled = true
				AimLine.visible = true
		updateFilling()
	
	if fireValue > 0.0 and not extending and not retracting and cooldown <= 0.0 and hitMonsters.size() == 0:
		if Data.of("sword.javelin"):
			var newVal = min(javelinMaxCharge, javelinCharge + delta * 12 * max(0.02, pow(javelinCharge, 3)))
			if javelinCharge < javelinMaxCharge and newVal >= javelinMaxCharge:
				$Blade/Sprite2D.play("charged"+bladeSuffix)
				$JavelinReadySound.play()
			javelinCharge = newVal
		
		else:
			extend()
			speed = 0
	
	if fireValue <= 0.0:
		if extending and not retracting:
			retract()
		elif javelinCharge > 0.0:
			if javelinCharge >= javelinMaxCharge:
				shootJavelin()
				javelinCharge = 0.0
			else:
				javelinCharge -= delta
	
	if javelinCharge >= javelinMaxCharge:
		# Fully charged
		if not $JavelinChargedSound.playing:
			$JavelinChargedSound.play()
		$Blade/JavelinCharge.visible = true
		$Blade/JavelinCharge.play("charged")
		if not $Blade/JavelinChargeParticles.emitting:
			$Blade/JavelinChargeParticles.emitting = true
		$JavelinChargingSound.stop()
		updateFilling()
	elif javelinCharge > 0.0:
		# Charging
		if fireValue > 0.0:
			if not javelinCharging:
				$JavelinChargingSound.stop()
			javelinCharging = true
		else:
			javelinCharging = false
		if not $JavelinChargingSound.playing:
			$JavelinChargingSound.play()
		if cooldown == 0.0:
			$JavelinChargingSound.pitch_scale = 0.5 + javelinCharge * 3
		updateFilling()
	else:
		# Not charged
		$Blade/JavelinCharge.visible = false
		$Blade/JavelinChargeParticles.emitting = false
		$JavelinChargedSound.stop()
		$JavelinChargingSound.stop()
		updateFilling()
	
	if extending:
		if extendPause > 0.0:
			extendPause -= delta
		else:
			var stabRange = Data.of("sword.stabRange")
			extendProgress = clamp(bladeExtension / 200.0, 0.0, 1.0)
			# last bit slows down the initial extend phase
			var extendSpeed = Data.of("sword.extendSpeed") * Data.of("sword.stabspeed")
			if Data.of("sword.stabManualSpeedup"):
				extendSpeed += extendSpeed * specialValue * 1.5
			var bladeMove = delta * extendSpeed * (0.2 + 4 * min(0.2, extendProgress))
			bladeExtension += bladeMove
			$MoveSound.pitch_scale = 4.0 + 4.0 * clamp(bladeExtension / stabRange, 0.0, 1.0)
			if bladeExtension > stabRange:
				bladeExtension = stabRange
				retract()
				$EndOfRopeSound.play()
			else:
				if autoAimTarget:
					var targetDir = (autoAimTarget.global_position) - ($Blade.global_position)
					var rot = targetDir.dot(Vector2.UP.rotated($Blade.rotation))
					# DOES NOT WORK
					$Blade.rotation += delta * rot * 1
				else:
					var goal = move.x * max(0.4, Data.of("sword.extendMove") * Data.of("sword.stabspeed"))
					extendRotation += delta * 13 * (goal-extendRotation)
					$Blade.rotation += delta * extendRotation
				$Blade.position += Vector2.UP.rotated($Blade.rotation) * bladeMove
				var newPointPos = $Blade.position - bladeTrailOffset
				if (newPointPos - $BladeTrail.get_point_position($BladeTrail.get_point_count()-1)).length() > 2.0:
					$BladeTrail.add_point(newPointPos)
#	elif javelinShot and lastJavelin:
#		var goal = move.x * max(0.4, Data.of("sword.extendMove") * Data.of("sword.stabspeed"))
#		extendRotation += delta * 4 * (goal - extendRotation)
#		lastJavelin.rotation += delta * extendRotation
	elif retracting:
		var retraction = delta * Data.of("sword.retractSpeed") * Data.of("sword.stabspeed")
		bladeExtension -= retraction
		updateFilling()
		if bladeExtension <= 0.0 or $BladeTrail.get_point_count() == 1:
			onRetractCompleted()
		else:
			var safeguard := 10
			var startPos:Vector2 = $Blade.position
			var pos = startPos
			while retraction > 0.0 and safeguard > 0:
				safeguard -= 1
				var nextPos = $BladeTrail.get_point_position($BladeTrail.get_point_count()-1) + bladeTrailOffset
				var d = nextPos - pos
				var stepDist = d.length()
				if stepDist > retraction:
					pos += d.normalized() * retraction
					retraction = 0.0
				else:
					retraction = max(0, retraction - stepDist)
					pos = nextPos
					$BladeTrail.remove_point($BladeTrail.get_point_count()-1)
					if $BladeTrail.get_point_count() == 1 or retraction == 0.0:
						break
			
			if $BladeTrail.get_point_count() <= 1:
				$Blade.position = bladeBasePos
				$Blade.rotation = 0
			else:
				$Blade.position = pos
				$Blade.rotation = (pos - startPos).angle() - PI*0.5
			if not $RetractingSound.playing:
				$RetractingSound.play()
	
	if not retracting and not extending:
		$MoveSound.pitch_scale = 0.5 + 0.5 * abs(speed)
		$MoveSound.volume_db = baseMoveVolume - 14 + min(18, abs(speed) * 40)
	
	var bladeDelta : float = (BladeCollisionShape.global_position - lastHitAreaPosition).rotated(-BladeCollisionShape.global_rotation).x
	var shapeCount:int = followBladeCollisionShapes.size() + 1
	for i in range(1, shapeCount):
		followBladeCollisionShapes[i-1].position.x = BladeCollisionShape.position.x - remap(i, 0, shapeCount, 0, bladeDelta*(5.0))
	lastHitAreaPosition = BladeCollisionShape.global_position
	
	for m in piercedMonsters.duplicate():
		var val = piercedMonsters[m] - delta
		if val <= 0:
			piercedMonsters.erase(m)
		else:
			piercedMonsters[m] = val
	
	if hitMonsters.size() > 0:
		if extending:
			if $Blade/Bombtip.visible:
				var explosion = load("res://content/shared/explosions/DirectionalExplosion" + str(Data.of("sword.stabExplosive")) + ".tscn").instantiate()
				explosion.rotation = rotation + $Blade.rotation - CONST.PI_HALF
				explosion.position = $Blade/Bombtip.global_position
				explosion.damage = Data.of("sword.stabExplosiveDamage")
				get_parent().add_child(explosion)
				$Blade/Bombtip.visible = false
				extendPause = 0.2
				return
			for m in hitMonsters:
				if not piercedMonsters.has(m):
					var dmg = min(remainingPierceDamage, m.currentHealth)
					if dmg < m.currentHealth:
						impact()
					m.hit("swordstabfast1", dmg, 5 * dmg)
					piercedMonsters[m] = 1.0
					if not Data.of("sword.stabContinuousStabbing"):
						remainingPierceDamage -= dmg
					if remainingPierceDamage <= 0:
						retract()
		else:
			# SLICING
			var electroDamage = Data.of("sword.electricDamage")
			for m in hitMonsters:
				var speedFactor := pow(abs(speed),1.65)
				var slicedmg = Data.of("sword.sliceDamage")
				var dmg:float = slicedmg * speedFactor
				
				if electroDamage > 0:
					m.hit("swordelectrified", electroDamage, 100)
				
				if (abs(speedFactor) < 0.4 and dmg < m.currentHealth) or abs(speedFactor) < 0.12:
					if dmg < m.currentHealth and m.currentHealth <= 2:
						m.hit("sword", m.currentHealth, 0)
					elif abs(speedFactor) > 0.1:
						$Tween.interpolate_property(self, "scale", Vector2(0.8, 0.8), Vector2(1,1), 1.0, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
						$Tween.interpolate_property($Blade, "rotation", -0.3 if randf() < 0.5 else 0.3, 0, 0.3)
						$Tween.start()
						if not $TooSlowSound.playing:
							$TooSlowSound.play()
					# when too slow, don't slice
					# however, if the monster health is very low, slice should still happen (like with the tick)
					break
				m.hit("sword", dmg, 30*abs(speed))
				impact()
				var relativeBrake = clamp(m.currentHealth / dmg, 0.0, 1.0)
				speed *= 1.0 - relativeBrake * Data.of("sword.sliceBrake")
				if abs(speedFactor) > 0.8 and relativeBrake >= 0.1 and not $HitSound.playing:
					$HitSound.play()
				elif not $SmallHitSound.playing:
					$SmallHitSound.play()
			
			if electroDamage > 0:
				$Blade/Sparks.play("spark"+str(randi()%3))
				$SparksSound.play()
			hitMonsters.clear()
	
	
	var newOffset = pathProbe.progress_ratio + delta * speed
	if newOffset < 0.05 and speed < 0:
		speed = speed - speed * min((0.5/newOffset), 15.0) * delta
	if newOffset > 0.95 and speed > 0:
		speed = speed - speed * min(0.5/(1.0-newOffset), 15.0) * delta
	newOffset = clamp(newOffset, 0.01, 0.99)
	# Smash the ground
	var currentOffset = pathProbe.progress_ratio
	
	var angularVelocity = abs(newOffset - currentOffset)/delta
	if (newOffset <= 0.03 or newOffset >= 0.97) and angularVelocity > 0.5 and brakeCooldownAfterBounce <= 0.0:
#		var dust = preload("res://content/weapons/sword/DustCloud.tscn").instance()
#		dust.position = $Blade/Sprite.global_position + $Blade/Sprite.global_position.normalized() * 30
#		if $Blade/Sprite.global_position.x < 0:
#			dust.flip()
#		$SmashSound.play()
#		Level.viewports.addElement(dust)
		
		# This make the sword bounce when it hits the ground
		# and starts it moving in the opposite direction
		# It's a small speed buff 
		var bounce = Data.of("sword.sliceBounceBack")
		if bounce > 0.0:
			speed = Data.of("sword.sliceBounceBack") * -$Blade/Sprite2D.global_position.normalized().x
			brakeCooldownAfterBounce = 0.2
			$SmashSound.play()
			InputSystem.shake(40, 0.2)
		else: 
			speed = 0.0
	
	# Motion speed blur
	$Blade/BladeParticles.process_material.angle_min = -rotation_degrees
	$Blade/BladeParticles.process_material.angle_max = -rotation_degrees
	if angularVelocity > 0.5:
		$Blade/BladeParticles.emitting = true
	else:
		$Blade/BladeParticles.emitting = false
		
	# Sword glows red then white as it speeds up
	$Blade/Sprite2D.modulate = Color(1+angularVelocity*5,1+angularVelocity*3,1+angularVelocity*3,1)
	
	pathProbe.progress_ratio = newOffset
	
	if newOffset < 0.01 or newOffset > 0.99:
		speed = 0
	
	if AimRayCast.enabled:
		var c = AimRayCast.get_collider()
		if c and c.is_in_group("monster"):
			var collisionPoint = AimRayCast.get_collision_point()
			var endPos = Vector2(0,-1) * ((collisionPoint - $Blade.global_position).length() + 5)
			c.aim()
			AimLine.set_point_position(1, endPos)
#			if extending and not autoAimTarget and Data.of("sword.aimTargetLock"):
#				autoAimTarget = c
#				if not autoAimTarget.is_connected("died", self, "autoAimTargetDied"):
#					autoAimTarget.connect("died", self, "autoAimTargetDied", [autoAimTarget])
		else:
			AimLine.set_point_position(1, Vector2.UP * 600)


func impact():
	var impact = Impact.instantiate()
	impact.global_position = $Blade.global_position + Vector2(0, -16).rotated(global_rotation)
	if extending:
		impact.global_rotation = global_rotation - PI/2
	else:
		impact.global_rotation = global_rotation
		if speed < 0:
			impact.flip_h = true
	Level.viewports.addElement(impact)

func autoAimTargetDied(t):
	if autoAimTarget and t == autoAimTarget:
		autoAimTarget = null

func onRetractCompleted():
	retracting = false
	var relExtension = maxExtension / Data.of("sword.stabRange")
	var relStabbing = 1.0 - remainingPierceDamage / Data.of("sword.stabDamage")
	cooldown = Data.of("sword.stabCooldown")
	cooldown = 0.5 * cooldown + max(relExtension, relStabbing) * 0.5 * cooldown
	maxCooldown = cooldown
	$BladeTrail.clear_points()
	bladeExtension = 0.0
	$Blade.position = bladeBasePos
	$Blade.rotation = 0.0
	$RetractedSound.play()
	$Base/BaseEffect.frame = 0
	$Base/BaseEffect.play("retracted")
	InputSystem.shake(60, 0.25)
	if arrowUnlocked:
		hideArrow()
	
	if active and Data.of("sword.aimLine"):
		AimLine.visible = true
	else:
		AimLine.visible = false
	 
	if not active:
		$SparksSound.stop()
		move *= 0

func extend():
	$Base/BaseEffect.frame = 0
	$Base/BaseEffect.play("impact")
	InputSystem.shake(30, 0.1)
	$Blade/Sprite2D.play("cooldown"+bladeSuffix)
	extending = true
	$ChargeSound.play()
	$MoveSound.volume_db = 0
	$Blade/MoveParticles.emitting = true
	$BladeTrail.add_point(Vector2(0,0))
	$BladeTrail.default_color = Style.STRUCT_BRIGHT
	var bombState = Data.of("sword.stabexplosive") - 1
	if bombState >= 0:
		$Blade/Bombtip.frame = bombState
		$Blade/Bombtip.visible = true
		$Blade/Bombtip.position.y = fillingY - 8
	
	remainingPierceDamage = Data.of("sword.stabDamage")
	extendRotation = 0
	
	if arrowUnlocked:
		showArrow()

func shootJavelin():
	javelinShot = true
	var javeling = preload("res://content/weapons/sword/JavelinBlade.tscn").instantiate()
	javeling.remainingPierceDamage = Data.of("sword.stabDamage")
	javeling.position = $Blade.global_position
	javeling.rotation = $Blade.global_rotation
	javeling.add_child($Blade/ArrowLeft.duplicate())
	javeling.add_child($Blade/ArrowRight.duplicate())
	var sprite = $Blade/Sprite2D.duplicate()
	sprite.play("charged" + bladeSuffix)
	javeling.add_child(sprite)
	javeling.add_child($Blade/MoveParticles.duplicate())
	javeling.setCollisionShapes(BladeCollisionShape, $Blade/HitArea/ArrowHead)
	Level.viewports.addElement(javeling)
	InputSystem.shake(60, 0.25)
	$JavelinFireSound.play()
	$Blade/Sprite2D.play("init"+bladeSuffix)
	cooldown = 0.1
	javelinCharge = 0.0
	$Base/BaseEffect.frame = 0
	$Base/BaseEffect.play("retracted")
	updateFilling()
	$RechargeSound.stop()
	extendRotation = 0
	
	var bombState = Data.of("sword.stabexplosive") - 1
	if bombState >= 0:
		var bombsprite = $Blade/Bombtip.duplicate()
		bombsprite.frame = bombState
		bombsprite.visible = true
		bombsprite.position.y = fillingY - 8
		javeling.addBomb(bombsprite)

func retract():
	extending = false
	autoAimTarget = null
	piercedMonsters.clear()
	maxExtension = bladeExtension
	updateFilling()
	retracting = true
	$MoveSound.pitch_scale = 0.2
	$MoveSound.volume_db = 0
	AimRayCast.enabled = false
	AimLine.visible = false
	$Blade/Bombtip.visible = false
	$Blade/MoveParticles.emitting = false

func updateFilling():
	var f = 0.0
	if javelinCharge > 0.0:
		f = (javelinCharge / javelinMaxCharge) * maxFilling
	elif javelinShot:
		pass
	else:
		if retracting and maxExtension > 0.0:
			var relExtension = bladeExtension / maxExtension
			f = clamp((maxFilling+1) * (1.0 - relExtension), 0, maxFilling)
		elif maxCooldown > 0.0:
			f = clamp((maxFilling+1) * (cooldown / maxCooldown), 0, maxFilling)
	
	$Blade/Filling.region_rect.size.y = f
	$Blade/Filling.region_rect.position.y = maxFilling - f
	$Blade/Filling.position.y = fillingY + maxFilling - f
	$Blade/Filling.offset.y = 0

func start():
	$BladeTrail.visible = true
	if not retracting and cooldown == 0.0:
		$Blade/Sprite2D.play("on"+bladeSuffix)
		$MoveSound.pitch_scale = 0.5
		$MoveSound.volume_db = -6
		$MoveSound.play()
	active = true
	if Data.of("sword.aimLine"):
		AimLine.visible = true
		AimRayCast.enabled = true
	
	BladeCollisionShape.disabled = false
	for shape in followBladeCollisionShapes:
		shape.disabled = false
	
func stop():
	active = false
	$SparksSound.stop()
	if extending:
		retract()
		return
	
	if cooldown > 0.0 or retracting:
		return
	
	$Blade/Sprite2D.play("off"+bladeSuffix)
	$BladeTrail.hide()
	$MoveSound.stop()
	if Data.of("sword.aimLine"):
		AimLine.visible = false
		AimRayCast.enabled = false
	
	BladeCollisionShape.disabled = true
	for shape in followBladeCollisionShapes:
		shape.disabled = true

	move *= 0
	additionalBreakFromMouse = 0

func _on_HitArea_area_entered(area):
	if area.is_in_group("monster"):
		addToHitMonsters(area)


func _on_HitArea_area_exited(area):
	if area.is_in_group("monster"):
		removeFromHitMonsters(area)

func addToHitMonsters(m):
	if not hitMonsters.has(m):
		hitMonsters.append(m)
		if not m.is_connected("died", Callable(self, "removeFromHitMonsters")):
			m.connect("died", Callable(self, "removeFromHitMonsters").bind(m))

func removeFromHitMonsters(m):
	if hitMonsters.has(m):
		hitMonsters.erase(m)
		m.disconnect("died", Callable(self, "removeFromHitMonsters"))

func _on_ReflectionArea_area_entered(area:Area2D) -> void:
	$ReflectSound.play()
	var dup = $Base/BaseEffect.duplicate(Node.DuplicateFlags.DUPLICATE_USE_INSTANTIATION)
	get_parent().add_child(dup)
	dup.visible = true
	dup.frame = 0
	dup.connect("animation_finished", Callable(dup, "queue_free"))
	dup.position = area.global_position - get_parent().global_position
	dup.rotation = dup.position.angle() + CONST.PI_HALF
	dup.offset.y = -24
	
	if Data.of("sword.reflectprojectiles") and area.reflectable:
		dup.play("reflect")
		area.domeReflectsDamage(0.0, Data.of("sword.reflectionAcceleration"), 2.0)
		area.damageSource = "swordreflection1"
	else:
		dup.play("impact")
		area.domeReflectsDamage(100.0, 0.0)
	
	if Data.of("sword.reflectProjectilesExplosive") and area.reflectable:
		area.spawnOnFree = load("res://content/shared/explosions/Explosion2.tscn").instantiate()
		area.spawnOnFree.damageSource = "swordexplosivereflection"
	
	$Tween.interpolate_property($Base, "modulate", Color.WHITE*10, Color.WHITE, 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$Tween.start()

func setBase(variant:int):
	$Base.play(str(variant))
	for i in range(0, $Base/ReflectionArea.get_child_count()):
		$Base/ReflectionArea.get_child(i).disabled = i != variant

func _on_Sprite_animation_finished() -> void:
	if $Blade/Sprite2D.animation.begins_with("on"):
		if Data.of("sword.electricDamage") > 0:
			_on_Sparks_animation_finished()
			$SparksSound.play()
		


#func _on_Sparks_animation_finished():
#	if not active:
#		$Sparks.hide()
#		$SparksSound.stop()
#		return
#
#
#	$Sparks.play("spark"+str(randi()%5))
#
#	if extending or retracting or cooldown > 0:
#		$Sparks.play("idle")
#		$SparksSound.stop()
#		return
		
#	var prob = rand_range(0,100)
#	if prob < 60:
#		$Sparks.play("idle")
#		$SparksSound.volume_db = -100
#	else:
#		var anim = "spark%d" % (randi() % 5)
#		$Sparks.play(anim)
#		$SparksSound.volume_db = 0
#		if not $SparksSound.playing:
#			$SparksSound.play()

func _on_Sparks_animation_finished():
	if not active:
		return
	if $Blade/Sparks.animation.begins_with("idle"):
		$Blade/Sparks.play("spark" + str(randi()%3))
		$Blade/Sparks.frame = 0
	else:
		$Blade/Sparks.play("idle" + str(1+randi()%3))

func getFireName():
	return "level.station.battle.navbar.stab"

func getSpecialName():
	if Data.of("sword.stabManualSpeedup"):
		return "level.station.battle.navbar.stabspeedup"
	else:
		return ""

func remove():
	pathProbe.queue_free()
	queue_free()

func onGameLost():
	$Base/ReflectionArea.set_deferred("monitoring", false)
	$Blade/HitArea.set_deferred("monitoring", false)
