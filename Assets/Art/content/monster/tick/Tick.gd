extends "res://content/monster/Monster.gd"

enum Phase {THROWN, WALK, JUMP, EXPLODE}
var phase:int = Phase.WALK

var path:Path2D
var target:Vector2

var progress := 0.0
var targetProgress:int
var speedScale:float
var offset:Vector2
var throwTargetPos:Vector2

func init():
	if phase == Phase.THROWN:
		var delay := randf_range(0.0, 0.1)
		animation("jump")
		phase = Phase.JUMP
		setFlip(position.x > throwTargetPos.x)
		var peakY = (throwTargetPos.y + position.y) * 0.5 - 30 - randf() * 20
		moveTween.interpolate_property(self, "position:x", position.x, throwTargetPos.x, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN, delay)
		moveTween.interpolate_property(self, "position:y", position.y, peakY , 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT, delay)
		moveTween.interpolate_property(self, "position:y", peakY, throwTargetPos.y, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN, delay + 0.5)
		moveTween.interpolate_callback(self, delay + 2 * 0.5, "finishThrow")
		moveTween.start()
	else:
		position = path.curve.sample_baked(0) + path.position
		startWalking()
		offset = Vector2(0, randf_range(-5,5))
	
	$Sprite2D.play("walk")
	updateHitboxState()
	speedScale = 0.9 + randf() * 0.2
	speedModifier *= speedScale
	targetProgress = 70 + 30 * randf()

func startWalking():
	phase = Phase.WALK
	animation("walk")
	setFlip(position.x > 0.0)
	$Sprite2D.frame = randi() % $Sprite2D.sprite_frames.get_frame_count("walk")

func finishThrow():
	progress = path.curve.get_closest_offset(position - path.position)
	offset = path.curve.get_closest_point(position) - position
	moveTween.interpolate_callback(self, randf_range(0.05, 0.2), "startWalking")
	moveTween.start()

func subProcess(delta):
	match phase:
		Phase.THROWN:
			animation("jump")
		Phase.WALK:
			progress += delta * Data.of("tick.speed") * $Sprite2D.speed_scale
			if abs(target.x - global_position.x) < targetProgress:
				animation("jump")
				phase = Phase.JUMP
				var peakY = (target.y+position.y)*0.5 -30 - randf()*20
				moveTween.interpolate_property(self, "position:x", position.x, target.x, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.4)
				moveTween.interpolate_property(self, "position:y", position.y, peakY , 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.4)
				moveTween.interpolate_property(self, "position:y", peakY, target.y, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN, 0.9)
				moveTween.interpolate_callback(self, 1.4, "set", "phase", Phase.EXPLODE)
				moveTween.start()
				$JumpSound.play()
			else:
				position = path.curve.sample_baked(progress) + path.global_position + offset
		Phase.EXPLODE:
			animation("explode")

func leave(delta:float):
	if progress > 0.0 and phase == Phase.WALK:
		progress = max(0, progress - delta * Data.of("tick.speed") * $Sprite2D.speed_scale)
		position = path.curve.sample_baked(progress) + path.global_position

func onGameLost():
	if currentHealth > 0:
		leaving = true
		if phase == Phase.WALK:
			animation("walk")
			$Sprite2D.speed_scale = 0.9 + randf() * 0.5
			setFlip(not $Sprite2D.flip_h)
		else:
			if not dead:
				die()
				animateDeath()

func handleFullStun():
	animation("hit")

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	if $Sprite2D.animation == "die" or $Sprite2D.animation == "explode":
		super.removeFreeBlocker()

func resumeAfterStagger():
	# jump might be interrupted
	receiveDamage = 99

func stagger():
	receiveDamage = 99

func applyDamage():
	Level.dome.requestMeleeDamage(Data.of("tick.damage") * damageModifier, global_position, self)
	InputSystem.shake(40, 0.3, 8, global_position)

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "explode" and $Sprite2D.frame == 7:
		applyDamage()
		die()
		$DieSoundExplode.play()
#	if $Sprite.animation == "walk" and ($Sprite.frame == 3 or $Sprite.frame == 7):
#		var d = FootstepDust.instance()
#		add_child(d)
#		d.set_size(0.3, 0.3)
#		d.global_position = global_position + Vector2(0, 2)

func animateDeath():
	$DieSound.play()
	animation("die")

