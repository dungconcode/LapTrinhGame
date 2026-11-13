extends "res://content/monster/Monster.gd"

const TeleportsToAttack := 7
const FlickersPerTeleport := 1

var nextLongIdle := 0

signal move_finished

enum Phase {MOVE_IN, ATTACK, IDLE, DIE}

var projetileTargetProvider
var movePointProvider
var phase:int
var cooldown := 0.0
var nextSide:String
var teleportsLeft:=-1
var path:Path2D
var meleeTarget:Path2D
var targetPos:Vector2
var meleeTargetProvider

var offsetHigh := true
var attacks := 0

var offset:Vector2

func init():
	teleportsLeft = TeleportsToAttack * FlickersPerTeleport
	cooldown = 0.1
	phase = Phase.MOVE_IN
	setHittable(false)
	position = Vector2.UP * -2000
	$AppearSound.play()
	offset = Vector2(0, randf_range(-30, 0))

func moveToDome(side:String):
	if teleportsLeft <= 0:
		teleportsLeft = (TeleportsToAttack * FlickersPerTeleport) + 1
	teleportsLeft -= 1
	offsetHigh = int(teleportsLeft / float(FlickersPerTeleport)) % 2 == 0
	var progress = 1.1 - float(snapped(teleportsLeft, FlickersPerTeleport)) / float(TeleportsToAttack * FlickersPerTeleport)
	position = path.position + path.curve.sample_baked(progress * path.curve.get_baked_length()) - $HitPosition.position + offset
	setFlip(position.x > 0)
	if teleportsLeft > 0:
		position.y -= randf_range(110, 160) if offsetHigh else randf_range(30, 90)
		position.x += randf_range(-30, 30)
		position.x = clamp(position.x, -470, 470)
		animation("appear")
		cooldown = 99
		phase = Phase.MOVE_IN
	else:
		startAttack()
	
	if teleportsLeft % FlickersPerTeleport == FlickersPerTeleport - 1:
		$AppearSound.play()
	else:
		$AppearQuickSound.play()

func startAttack():
	attacks = 1
	phase = Phase.ATTACK
	animation("appear")
	

func subProcess(delta):
	if cooldown > 0.0:
		cooldown -= delta
		return

	match phase:
		Phase.MOVE_IN:
			moveToDome(nextSide)
		Phase.IDLE:
			playDisappearParticles()
			animation("disappear")
			if teleportsLeft % FlickersPerTeleport == 0:
				cooldown = Data.stabilizedRandomFloat(0.2, 0.4, "phasercooldown", 2)
				nextLongIdle = randi() % FlickersPerTeleport
			phase = Phase.MOVE_IN

func playDisappearParticles():
	$Sprite2D/DisappearParticlesR.emitting = true
	$Sprite2D/DisappearParticlesL.emitting = true
	$Sprite2D/DisappearParticlesR.restart()
	$Sprite2D/DisappearParticlesL.restart()

func leave(delta:float):
	pass

func onGameLost():
	if currentHealth > 0:
		leaving = true
		if phase == Phase.ATTACK:
			playDisappearParticles()
			animation("attack_disappear")
		else:
			playDisappearParticles()
			animation("disappear")

func handleFullStun():
	animation("hit")

func resumeAfterStagger():
	cooldown = 1.0
	playDisappearParticles()
	animation("disappear")

func animateDeath():
	$DieSound.play()
	animation("die")
	phase = Phase.DIE

func hitDome():
	Level.dome.requestMeleeDamage(Data.of("phaser.damage") * damageModifier, $HitPosition.global_position, self)
	InputSystem.shake(140, 0.3, 8, $HitPosition.global_position)
	$DomeHitSound.play()

func resetAfterAttack():
	teleportsLeft = 1
	cooldown = Data.stabilizedRandomFloat(0.2, 0.8, "phaserattack", 2.0)
	phase = Phase.MOVE_IN 
	nextSide = CONST.LEFT if nextSide == CONST.RIGHT else CONST.RIGHT
	Level.world.freePathOccupation(Data.of("phaser.movetype"), path, self)
	path = Level.world.assignRandomPath(Data.of("phaser.movetype"), nextSide, self)
	setFlip(nextSide == CONST.RIGHT)

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	if $Sprite2D.frame == 0:
		if not $Sprite2D.is_playing():
			$Sprite2D.play($Sprite2D.animation)
			return
	
	match $Sprite2D.animation:
		"appear":
			if phase == Phase.ATTACK:
				if attacks > 0:
					$Sprite2D.speed_scale = 1.0
					animation("attack_windup")
				else:
					playDisappearParticles()
					animation("attack_disappear")
			elif phase == Phase.MOVE_IN:
				animation("idle")
				cooldown = Data.stabilizedRandomFloat(0.4, 1.0, "phaserteleport", 2.0)
				phase = Phase.IDLE
		"attack_disappear":
			playDisappearParticles()
			if leaving:
				removeFreeBlocker()
				removeFreeBlocker()
				visible = false
			else:
				resetAfterAttack()
		"attack":
			if attacks > 0:
				$Sprite2D.speed_scale = 1.0
				animation("attack_windup")
			else:
				playDisappearParticles()
				animation("attack_disappear")
		"attack_windup":
			playDisappearParticles()
			animation("attack")
		"die":
			removeFreeBlocker()
		"disappear":
			if leaving:
				removeFreeBlocker()
				removeFreeBlocker()
				visible = false
			elif phase == Phase.ATTACK:
				playDisappearParticles()
				resetAfterAttack()
			

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "attack" and $Sprite2D.frame == 1:
		hitDome()
		attacks -= 1
	elif $Sprite2D.animation == "attack_windup" and $Sprite2D.frame == 1:
		$WindupSound.play()
	elif $Sprite2D.animation == "attack_disappear" and $Sprite2D.frame == 11:
		setHittable(false)
	elif $Sprite2D.animation == "disappear" and $Sprite2D.frame == 2:
		setHittable(false)
	elif $Sprite2D.animation == "disappear" and $Sprite2D.frame == 0:
		if teleportsLeft % FlickersPerTeleport == 0:
			$DisappearSound.play()
	elif $Sprite2D.animation == "appear" and $Sprite2D.frame == 1:
		setHittable(true)
	elif $Sprite2D.animation == "appear" and $Sprite2D.frame == 0:
		$Sprite2D.speed_scale = 1.0 - pow((float(TeleportsToAttack) / (teleportsLeft + 1)), 2)


