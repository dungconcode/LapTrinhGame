extends "res://content/monster/Monster.gd"

signal move_finished


enum Phase {ENTER, SHOOT, SHRINK, GROW, PROTECTED, ARMOFF, DIE}
var phase:int = Phase.ENTER

var movePointProvider
var projectileTargetProvider

var entering := true

var cooldown := 0.0
var nextProtectionHealthThreshold:float

var pathProgress := 0.0
var currentMoveCurve:Curve2D

func setProviders(movePointProvider, projectileTargetProvider, side:String):
	self.movePointProvider = movePointProvider
	self.projectileTargetProvider = projectileTargetProvider
	var spawnType = Data.of("scarab.spawnpoint") + "_" + side
	position = movePointProvider.getSpawn(spawnType).position

func init():
	var goalPos = movePointProvider.assignRandomPoint(CONST.CENTER, self).position
	currentMoveCurve = Curve2D.new()
	$EnterSound.play()
	currentMoveCurve.add_point(position)
	currentMoveCurve.add_point(goalPos)
	var pathLength = currentMoveCurve.get_baked_length()
	var time = pathLength / float(Data.of("scarab.speed"))
	moveTween.interpolate_property(self, "pathProgress", 0, pathLength, time, Tween.TRANS_QUAD, Tween.EASE_OUT)
	moveTween.start()
	phase = Phase.ENTER
	
	$Sprite2D.play("idle")
	updateHitboxState()
	setFlip(position.x > 0)
	nextProtectionHealthThreshold = 0.6 * maxHealth

func subProcess(delta):
	if phase == Phase.ARMOFF:
		return
	elif phase == Phase.SHOOT and currentHealth <= maxHealth * 0.33:
		armoff()
	
	if phase != Phase.SHRINK and phase != Phase.ENTER and currentHealth <= nextProtectionHealthThreshold:
		phase = Phase.SHRINK
		$Sprite2D.play("shrink")
		$InvulnerableStartSound.play()
		lowerProtectionThreshold()                       
		return
	
	if cooldown > 0.0:
		if phase != Phase.PROTECTED or timeSinceLastShotAt > 0.2:
			cooldown -= delta
		return
	
	match phase:
		Phase.ENTER:
			var newPos = currentMoveCurve.sample_baked(pathProgress)
			position = newPos
			if pathProgress >= currentMoveCurve.get_baked_length() - 1.0:
				startBigShot()
		Phase.PROTECTED:
			$Sprite2D.play("grow")
			$InvulnerableStopSound.play()
			phase = Phase.GROW
		Phase.SHOOT:
			startBigShot()
			if cooldown > 0.0:
				cooldown -= delta

func armoff():
	$SplitSound.play()
	animation("armoff")
	phase = Phase.ARMOFF
	nextProtectionHealthThreshold = -1
	for side in ["left", "right"]:
		var arm = preload("res://content/monster/scarab/ScarabArm.tscn").instantiate()
		var path = Level.world.getPath(Data.of("walker.movetype"), side)
		Level.monsters.registerMonster(arm)
#		if $Sprite.flip_h:
#			if side == "left":
#				side = "right"
#			elif side == "right":
#				side = "left"
		arm.position = find_child(side.capitalize() + "Arm").global_position
		arm.start(side, path)

func lowerProtectionThreshold():
#	nextProtectionHealthThreshold = currentHealth - maxHealth * 0.5
	nextProtectionHealthThreshold = -1

func leave(delta:float):
	position.y -= delta * 50
	position.x += delta * position.x * 0.1 

func onGameLost():
	if currentHealth > 0:
		leaving = true
		animation("idle")

func stagger():
	moveTween.stop_all()

func resumeAfterStagger():
	moveTween.resume_all()

func animateDeath():
	$Sprite2D.play("die")
	$QuickShotSound.stop()
	$MassShootSound.stop()
	$DieSound.play()

func startBigShot():
	phase = Phase.SHOOT

	animation("shoot")

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	match $Sprite2D.animation:
		"armoff":
			animation("quickshot")
		"shrink":
			animation("protected")
			cooldown = randf_range(5.0, 7.0)
			phase = Phase.PROTECTED
		"shoot":
			animation("idle")
			cooldown = 1.2
		"grow":
			startBigShot()
		"die":
			super.removeFreeBlocker()
		"quickshot":
			$QuickShotSound.play()

func _on_Sprite_frame_changed():
	match $Sprite2D.animation: 
		"grow":
			if $Sprite2D.frame == 8:
				invulnerable = false
				hitboxToDisable.append($HitboxQuickshot)
				hitboxToDisable.append($HitboxProtected)
				hitboxToEnable.append($HitboxDefault1)
				hitboxToEnable.append($HitboxDefault2)
				$InvulnerableHoldSound.stop()
		"shrink":
			if $Sprite2D.frame == 5:
				invulnerable = true
				stunIntensity = 0
				hitboxToDisable.append($HitboxDefault1)
				hitboxToDisable.append($HitboxDefault2)
				hitboxToDisable.append($HitboxQuickshot)
				hitboxToEnable.append($HitboxProtected)
				$InvulnerableHoldSound.play()
		"shoot":
			if $Sprite2D.frame == 12:
				spawnBigShot()
				$MassShootSound.play()
			elif $Sprite2D.frame == 2:
				$PreMassShootSound.play()
		"quickshot":
			if ($Sprite2D.frame == 3 or $Sprite2D.frame == 6 or $Sprite2D.frame == 9):
				spawnSmallShot(-1)
				spawnSmallShot(1)

func spawnBigShot():
	for offsetX in [-300, -250, -200, -150, 150, 200, 250, 300]:
		var p = preload("res://content/monster/scarab/ScarabProjectile.tscn").instantiate()
		p.damageSource = damageSource
		p.damage = Data.of("scarab.damage") * damageModifier
		p.speed = Data.of("scarab.shotspeed") * randf_range(0.9, 1.1)
		offsetX *= randf_range(0.9, 1.1)
		get_parent().add_child(p)
		var path = Curve2D.new()
		var shotDirection = Vector2(offsetX + position.x * 0.5, -abs(offsetX))
		var target = projectileTargetProvider.getRandom(shotDirection)
		path.add_point(position + $PositionBigProjectile.position, Vector2.ZERO, shotDirection)
		path.add_point(target, shotDirection)
		p.start(path, Tween.TransitionType.TRANS_CUBIC, Tween.EASE_OUT_IN)

func spawnSmallShot(dir):
	var x = randf_range(100, 300)
	x *= dir
	var y = randf_range(-100, -300)
	var p = preload("res://content/monster/scarab/ScarabProjectile.tscn").instantiate()
	p.damageSource = damageSource
	p.damage = Data.of("scarab.damage") * damageModifier
	p.speed = Data.of("scarab.shotspeed") * randf_range(0.9, 1.1)
	get_parent().add_child(p)
	var path = Curve2D.new()
	var shotDirection = Vector2(x, y)
	var target = projectileTargetProvider.getRandom(shotDirection)
	path.add_point(position + $PositionBigProjectile.position, Vector2.ZERO, shotDirection)
	path.add_point(target, shotDirection)
	$QuickShotSound.play()
	p.start(path, Tween.TRANS_CUBIC, Tween.EASE_OUT_IN)


