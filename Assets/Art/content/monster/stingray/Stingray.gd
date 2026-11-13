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

var entering := true
var pathProgress := 0.0
var curveRotationRadians := 0.5
var curveRotationStrength := 50

var line:Line2D

func setProviders(movePointProvider, projetileTargetProvider, side:String):
	self.movePointProvider = movePointProvider
	self.projetileTargetProvider = projetileTargetProvider
	nextSide = side
	var spawnType = Data.of("stingray.spawnpoint") + "_" + side
	position = movePointProvider.getSpawn(spawnType).position
	currentMoveCurve = Curve2D.new()

func init():
	startMove()

func createNextPath():
	pathProgress = 0
	var targetPos:Vector2 = movePointProvider.assignRandomPoint(nextSide + "_low", self).position
	nextSide = CONST.LEFT if nextSide == CONST.RIGHT else CONST.RIGHT 
	var direction = (targetPos - position).normalized()
	currentMoveCurve.clear_points()
	var rot = direction.rotated(PI*0.5 * curveRotationRadians - PI*curveRotationRadians*randf())*curveRotationStrength
	currentMoveCurve.add_point(position, Vector2.ZERO, rot)
	currentMoveCurve.add_point(targetPos, direction.rotated(PI*(1+curveRotationRadians*0.5) - PI*curveRotationRadians*randf())*curveRotationStrength)

func startMove():
	createNextPath()
	var pathLength = currentMoveCurve.get_baked_length()
	$Sprite2D.speed_scale = speedModifier
	var duration = pathLength / (Data.of("stingray.speed") * speedModifier)
	moveTween.interpolate_property(self, "pathProgress", 0, pathLength, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	moveTween.start()
	phase = Phase.MOVE
	animation("fly")

func subProcess(delta):
	match phase:
		Phase.MOVE:
			var pathLength = currentMoveCurve.get_baked_length()
			var newPos = currentMoveCurve.sample_baked(pathProgress)
			var moveDelta = position - newPos
			if pathProgress > 0.0 and moveDelta.length() > 0:
				setFlip(moveDelta.x > 0)
				$Sprite2D.rotation = moveDelta.angle()
				if not $Sprite2D.flip_h:
					$Sprite2D.rotation += PI
				
				$Sprite2D.speed_scale *= 1.0 + 0.2 * moveDelta.length()
			position = newPos
			if pathProgress >= pathLength - 10:
				animation("grow")
			if pathProgress >= pathLength:
				grow()
				emit_signal("move_finished")
				$Sprite2D.rotation = 0
		Phase.SHOOT:
			pass
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
		animation("idle")

func handleFullStun():
	animation("hit")

func stagger():
	animation("hit")

func resumeAfterStagger():
	if phase != Phase.MOVE:
		shrink()
	else:
		animation("fly")

func spawnShot():
	var p = preload("res://content/monster/flyer/FlyerProjectile.tscn").instantiate()
	p.damageSource = damageSource
	p.position = position + $ProjectilePosition.position
	p.origin = position
	p.target = projetileTargetProvider.getRandom(position) + Vector2(8-randi()%16, 8-randi()%16)
	p.damage = Data.of("stingray.damage") * damageModifier
	p.speed = Data.of("stingray.shotspeed")
	get_parent().add_child(p)
	$ShootSound.play()
	remainingShots -= 1

func shrink():
	animation("shrink")
	$ShrinkSound.play()
	phase = Phase.SHRINK

func grow():
	setFlip(position.x > 0)
	$AppearSound.play()
	phase = Phase.GROW

func startShoot():
	remainingShots = Data.stabilizedRandomInt(Data.of("stingray.minshots") ,Data.of("stingray.maxshots"), "stingrayshots", 4)
	
	phase = Phase.SHOOT
	updateShoot()

func updateShoot():
	if remainingShots > 0:
		animation("shoot" + str(1 + randi() % 3))
		$Sprite2D.frame = 0
	else:
		shrink()

func animateDeath():
	$DieSound.play()
	animation("die")
	phase = Phase.DIE

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()	

func _on_Sprite_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	if $Sprite2D.animation.begins_with("shoot"):
		updateShoot()
	elif $Sprite2D.animation == "die":
		super.removeFreeBlocker()
	elif $Sprite2D.animation == "shrink":
		startMove()
	elif $Sprite2D.animation == "grow":
		animation("idle")
		entering = false
	elif $Sprite2D.animation == "idle" and not leaving:
		startShoot()

func _on_Sprite_frame_changed():
	match $Sprite2D.animation:
		"shoot1":
			if $Sprite2D.frame == 3:
				spawnShot()
		"shoot2":
			if $Sprite2D.frame == 3:
				spawnShot()
		"shoot3":
			if $Sprite2D.frame == 3:
				spawnShot()
