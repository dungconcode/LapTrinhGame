extends "res://content/monster/Monster.gd"

enum Phase {WALK1, THREATEN, WALK2, JUMP, BASH, DIE}
var phase:int = Phase.WALK1

var path:Path2D
var meleeTarget:Path2D
var walking := true
var progress := 0.0
var targetProgress:float
var lastDelta:float
var targetOffset:float

var lastFrame:int

func init():
	position = path.curve.sample_baked(0) + path.global_position
	var d = position.x - (path.curve.sample_baked(50).x + + path.global_position.x)
	if d > 0.0:
		setFlip(true)
		targetOffset = 1.0 - randf() * 0.33
	else:
		targetOffset = 0.0 + randf() * 0.33
		setFlip(false)
	$Sprite2D.play("run")
	$Sprite2D.frame = randi() % $Sprite2D.sprite_frames.get_frame_count("run")
	$Sprite2D.speed_scale = speedModifier
	
	targetProgress = 80 + randf() * 100

func subProcess(delta):
	match phase:
		Phase.WALK1:
			progress += delta * Data.of("beast.speed") * stunLevel() * speedModifier
			if progress >= targetProgress:
				animation("threaten")
				phase = Phase.THREATEN
				$ThreatenSound.play()
			else:
				position = path.curve.sample_baked(progress) + path.global_position
		Phase.WALK2:
			progress += delta * Data.of("beast.speed") * stunLevel() * speedModifier
			if progress >= targetProgress:
				phase = Phase.JUMP
				var target = meleeTarget.curve.sample_baked(targetOffset * meleeTarget.curve.get_baked_length()) - $HitPosition.position
				var peakY = target.y + position.y - 10 - 10 * randf()
				moveTween.interpolate_property(self, "position:x", position.x, target.x, 0.7, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0.4)
				moveTween.interpolate_property(self, "position:y", position.y, peakY , 0.4, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.4)
				moveTween.interpolate_property(self, "position:y", peakY, target.y, 0.3, Tween.TRANS_QUAD, Tween.EASE_IN, 0.8)
				moveTween.interpolate_callback(self, 1.4, "startBash")
				moveTween.start()
				$JumpSound.play()
				animation("jump")
			else:
				position = path.curve.sample_baked(progress) + path.global_position

func startBash():
	phase = Phase.BASH
	animation("attack")

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()	

func _on_Sprite_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	match $Sprite2D.animation:
		"threaten":
			startWalk2()
		"die_attack":
			removeFreeBlocker()
		"die_run":
			removeFreeBlocker()

func startWalk2():
	phase = Phase.WALK2
	targetProgress = path.curve.get_baked_length() * (0.75 + randf() * 0.1)
	animation("run")

func animateDeath():
	if $Sprite2D.animation == "attack":
		animation("die_attack")
	else:
		animation("die_run")
	phase = Phase.DIE
	$DieSound.play()

func resumeAfterStagger():
	if phase == Phase.BASH:
		animation("attack")
	elif phase == Phase.THREATEN:
		startWalk2()
	elif phase == Phase.JUMP:
		animation("jump")
		$Sprite2D.frame = lastFrame
	elif phase != Phase.DIE:
		animation("run")

func applyDamage():
	Level.dome.requestMeleeDamage(Data.of("beast.damage") * damageModifier, $HitPosition.global_position, self)
	InputSystem.shake(40, 0.3, 8, $HitPosition.global_position)
	$PunchSound1.play()
	$PunchSound2.play()
	$PunchSound3.play()

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "attack" and ($Sprite2D.frame == 3 or $Sprite2D.frame == 8):
		applyDamage()
	elif $Sprite2D.animation == "jump":
		lastFrame = $Sprite2D.frame
#	elif $Sprite.animation == "run" and ($Sprite.frame == 2 or $Sprite.frame == 6):
#		var d = FootstepDust.instance()
#		add_child(d)
#		d.global_position = global_position + Vector2(0, 2)

func handleFullStun():
	if phase == Phase.WALK1 or phase == Phase.THREATEN or phase == Phase.WALK2:
		animation("hit_run")
	else:
		animation("hit_attack")

func onGameLost():
	if phase == Phase.JUMP or phase == Phase.BASH:
		animation("die_attack")
	else:
		leaving = true
		animation("walk")
		$Sprite2D.speed_scale = 0.9 + randf() * 0.5
		setFlip(not $Sprite2D.flip_h)
		
func leave(delta:float):
	if progress > 0.0:
		progress = max(0, progress - delta * Data.of("beast.speed") * $Sprite2D.speed_scale)
		position = path.curve.sample_baked(progress) + path.global_position


