extends "res://content/monster/Monster.gd"

signal move_finished

const delayBetweenShots = 0.0

enum Phase {GROW, SHOOT, SHRINK, MOVE, DIE}

var phase:int = Phase.MOVE

var remainingShots := 0

var nextSide:String
var movePointProvider
var projetileTargetProvider
var currentMoveCurve:Curve2D

var applyInRotation := false
var drawMovementLine := false
var pathProgress := 0.0
var curveRotationRadians := 0.75
var curveRotationStrength := 150

var cooldown := 0.0

func setProviders(movePointProvider, projetileTargetProvider, side:String):
	self.movePointProvider = movePointProvider
	self.projetileTargetProvider = projetileTargetProvider
	var spawnType = Data.of("flyer.spawnpoint") + "_" + side
	position = movePointProvider.getSpawn(spawnType).global_position
	nextSide = side
	currentMoveCurve = Curve2D.new()

func init():
	applyInRotation = true # don't come in wobbly
	startMove()
	setHittable(false)

func createNextPath():
	pathProgress = 0
	var targetPos:Vector2 = movePointProvider.assignRandomPoint(nextSide, self).global_position
	nextSide = CONST.LEFT if nextSide == CONST.RIGHT else CONST.RIGHT 
	var direction = (targetPos - position).normalized()
	currentMoveCurve.clear_points()
	var rot = direction.rotated(PI*0.5 * curveRotationRadians - PI*curveRotationRadians*randf())*curveRotationStrength if applyInRotation else Vector2.ZERO
	currentMoveCurve.add_point(position, Vector2.ZERO, rot)
	currentMoveCurve.add_point(targetPos, direction.rotated(PI*(1+curveRotationRadians*0.5) - PI*curveRotationRadians*randf())*curveRotationStrength)

func startMove():
	animation("fly")
	createNextPath()
	var pathLength = currentMoveCurve.get_baked_length()
	var duration = pathLength / Data.of("flyer.speed")
	moveTween.interpolate_property(self, "pathProgress", 0, pathLength, duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	moveTween.start()
	phase = Phase.MOVE

func subProcess(delta):
	if cooldown > 0.0:
		cooldown -= delta
		return
	
	match phase:
		Phase.MOVE:
			var pathLength = currentMoveCurve.get_baked_length()
			var newPos = currentMoveCurve.sample_baked(pathProgress)
			setFlip(position.x - newPos.x > 0)
			position = newPos
			$Sprite2D.speed_scale = speedModifier
			if pathProgress >= pathLength:
				grow()
				emit_signal("move_finished")
		Phase.SHOOT:
			$Sprite2D.speed_scale = stunLevel() * speedModifier
		Phase.SHRINK:
			pass
		Phase.GROW:
			pass

func leave(delta:float):
	position.y -= delta * 50
	position.x += delta * position.x * 0.1 

func onGameLost():
	if currentHealth > 0:
		leaving = true
		animation("fly")

func handleFullStun():
	animation("hit")

func stagger():
	if phase != Phase.MOVE:
		animation("hit")

func resumeAfterStagger():
	if phase != Phase.MOVE:
		shrink()

func spawnShot():
	var p = preload("res://content/monster/flyer/FlyerProjectile.tscn").instantiate()
	p.damageSource = damageSource
	p.position = position + $ProjectilePosition.position
	p.origin = position
	p.target = projetileTargetProvider.getRandom(position) + Vector2(8-randi()%16, 8-randi()%16)
	p.damage = Data.of("flyer.damage") * damageModifier
	p.speed = Data.of("flyer.shotspeed")
	get_parent().add_child(p)
	$ShootSound.play()
	remainingShots -= 1

func shrink():
	animation("shrink")
	$ShrinkSound.play()
	phase = Phase.SHRINK

func grow():
	animation("grow")
	setFlip(position.x > projetileTargetProvider.global_position.x)
	$AppearSound.play()
	phase = Phase.GROW

func startShoot():
	remainingShots = Data.stabilizedRandomInt(Data.of("flyer.minshots"), Data.of("flyer.maxshots"), "flyershots", 5)
	
	phase = Phase.SHOOT
	updateShoot()

func updateShoot():
	if remainingShots > 0:
		animation("shoot")
		$Sprite2D.frame = 0
	else:
		shrink()

func animateDeath():
	$DieSound.play()
	animation("die")
	phase = Phase.DIE

func _on_sprite_2d_animation_looped() -> void:
	_animationEndCheck()

func _on_Sprite_animation_finished():
	_animationEndCheck()

func _animationEndCheck() -> void:
	if $Sprite2D.animation == "shoot":
		updateShoot()
	elif $Sprite2D.animation == "die":
		super.removeFreeBlocker()
	elif $Sprite2D.animation == "shrink":
		startMove()
	elif $Sprite2D.animation == "grow":
		startShoot()

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "shrink" and $Sprite2D.frame == 3:
		setHittable(false)
	elif $Sprite2D.animation == "grow" and $Sprite2D.frame == 2:
		setHittable(true)
	elif $Sprite2D.animation == "shoot" and $Sprite2D.frame == 4:
		spawnShot()
