extends "res://content/monster/Monster.gd"

enum Phase {ENTER, SHOOT, DIE}

var phase:int = Phase.ENTER

var remainingShots := 0

var movePointProvider
var projetileTargetProvider
var currentMoveCurve:Curve2D

var applyInRotation := false
var pathProgress := 0.0
var averagedMoveDelta := 0.0
var curveRotationRadians := 0.75
var curveRotationStrength := 150

var line:Line2D
var cooldown := 0.0

func setProviders(movePointProvider, projetileTargetProvider, side:String):
	self.movePointProvider = movePointProvider
	self.projetileTargetProvider = projetileTargetProvider
	var spawnType = Data.of("bolter.spawnpoint") + "_" + side
	position = movePointProvider.getSpawn(spawnType).position
	currentMoveCurve = Curve2D.new()

func init():
	applyInRotation = true # don't come in wobbly
	setFlip(position.x > 0)
	
	pathProgress = 0
	var targetPos:Vector2 = projetileTargetProvider.getRandom(position) + Vector2(4-randi()%8, 4-randi()%8) - find_child("ShotPosition").position
	var direction = (targetPos - position).normalized()
	currentMoveCurve.add_point(position, Vector2.ZERO)
	var rot = direction.rotated(PI*1.25 * curveRotationRadians - 0.5*PI*curveRotationRadians*randf())*curveRotationStrength
	currentMoveCurve.add_point(targetPos, rot, Vector2.ZERO)
	
	animation("fly")
	var pathLength = currentMoveCurve.get_baked_length()
	# don't add speed mod or stun level here, as they are used to modulate playback speed of the tween
	var duration = pathLength / Data.of("bolter.speed")
	moveTween.interpolate_property(self, "pathProgress", 0, pathLength, duration, Tween.TRANS_QUAD, Tween.EASE_OUT)
	moveTween.interpolate_callback(self, duration, "startShooting")
	moveTween.start()
	
	$Bolt.play("default")

func subProcess(delta):
	if cooldown > 0.0:
		cooldown -= delta
		return
	
	match phase:
		Phase.ENTER:
			var oldPos := position
			position = currentMoveCurve.sample_baked(pathProgress)
			if averagedMoveDelta == 0.0:
				averagedMoveDelta = (position - oldPos).length()
			else:
				averagedMoveDelta = averagedMoveDelta * (1.0 - delta) + (position - oldPos).length() * delta
		Phase.SHOOT:
			pass

func startShooting():
	phase = Phase.SHOOT
	animation("shoot2")
	$ChargingShotSound.play()

func leave(delta:float):
	position.y -= delta * 50
	position.x += delta * position.x * 0.1 

func onGameLost():
	if currentHealth > 0:
		moveTween.stop_all()
		moveTween.remove_all()
		leaving = true
		setFlip(not $Sprite2D.flip_h)
		animation("fly")

func handleFullStun():
	animation("hit")

func resumeAfterStagger():
	if phase == Phase.SHOOT:
		animation("idle")
	else:
		animation("fly")

func hitDome():
	Level.dome.requestBeamDamage(Data.of("bolter.damage") * damageModifier, global_position, self)

func animateDeath():
	$DieSound.play()
	animation("die")
	phase = Phase.DIE

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	if $Sprite2D.animation == "die":
		super.removeFreeBlocker()
	elif $Sprite2D.animation == "shoot2":
		animation("idle")
	elif $Sprite2D.animation == "idle":
		animation("shoot2")
		$ChargingShotSound.play()

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "shoot2":
		if $Sprite2D.frame == 9:
			hitDome()
		elif $Sprite2D.frame == 5:
			$ShootSound.play()
		elif $Sprite2D.frame == 8:
			InputSystem.shake(80, 0.2, 8, global_position)
		elif $Sprite2D.frame == 0:
			$Bolt.play("bolt" + str(1 + randi() % 3))

func _on_Bolt_animation_finished():
	$Bolt.play("default")
