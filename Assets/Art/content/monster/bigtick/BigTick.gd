extends "res://content/monster/Monster.gd"

enum Phase {WALK, BURROW, EMERGE, JUMP, EXPLODE}
var phase:int = Phase.WALK

var path:Path2D
var target:Vector2

var pathBakedLength:float
var progress := 0.0
var burrowProgress := 0.0
var targetProgress:int
var burrowedCooldown:float
var offset:Vector2

func init():
	position = path.curve.sample_baked(0) + path.global_position
	var d = position.x - (path.curve.sample_baked(50).x + + path.global_position.x)
	setFlip(d > 0.0)
	$Sprite2D.play("walk")
	updateHitboxState()
	speedModifier *= 0.9 + randf() * 0.2
	$Sprite2D.frame = randi() % $Sprite2D.sprite_frames.get_frame_count("walk")
	targetProgress = 100+30*randf()
	pathBakedLength = path.curve.get_baked_length()
	burrowProgress = (0.1 + randf()* 0.4) * pathBakedLength
	offset = Vector2(0, randf_range(-3,3))

func subProcess(delta):
	
	match phase:
		Phase.WALK:
			progress += delta * Data.of("bigtick.speed") * $Sprite2D.speed_scale
			if progress > burrowProgress:
				burrowProgress += (0.1 + randf() * 0.4) * pathBakedLength
				if burrowProgress > 0.8 * pathBakedLength:
					burrowProgress = pathBakedLength
				burrow()
				return
			if abs(target.x - global_position.x) < targetProgress:
				animation("jump")
				phase = Phase.JUMP
				var peakY = (target.y+position.y)*0.5 -50 - randf()*20
				moveTween.interpolate_property(self, "position:x", position.x, target.x, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.4)
				moveTween.interpolate_property(self, "position:y", position.y, peakY , 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.4)
				moveTween.interpolate_property(self, "position:y", peakY, target.y, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN, 0.9)
				moveTween.interpolate_callback(self, 1.4, "explode")
				moveTween.start()
				$JumpSound.play()
			else:
				position = path.curve.sample_baked(progress) + path.global_position + offset
		Phase.BURROW:
			burrowedCooldown -= delta
			if burrowedCooldown <= 0.0:
				emerge()

func explode():
	phase = Phase.EXPLODE
	animation("explode")
	$Sprite2D.speed_scale = 1.0
	$DieSoundExplode.play()

func burrow():
	phase = Phase.BURROW
	burrowedCooldown = Data.of("bigtick.burrowtime") + randf() * 1.0
	animation("burrow")

func emerge():
	phase = Phase.EMERGE
	animation("emerge")
	setHittable(true)

func leave(delta:float):
	if progress > 0.0 and phase == Phase.WALK:
		progress = max(0, progress - delta * Data.of("bigtick.speed") * $Sprite2D.speed_scale)
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
	if $Sprite2D.animation == "die":
		super.removeFreeBlocker()
	elif $Sprite2D.animation == "explode":
		super.removeFreeBlocker()
		die()
	elif $Sprite2D.animation == "burrow":
		setHittable(false)
	elif $Sprite2D.animation == "emerge":
		phase = Phase.WALK
		animation("walk")

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "explode" and $Sprite2D.frame == 1:
		applyDamage()
#	elif $Sprite.animation == "walk" and ($Sprite.frame == 3 or $Sprite.frame == 7):
#		var d = FootstepDust.instance()
#		add_child(d)
#		d.set_size(0.5, 0.5)
#		d.global_position = global_position + Vector2(0, 2)

func resumeAfterStagger():
	# jump might be interrupted
	if phase == Phase.JUMP:
		receiveDamage = 99
	setHittable(true) # <- just in case it was burrowed
	animation("walk")
	phase = Phase.WALK

func stagger():
	animation("hit")

func applyDamage():
	Level.dome.requestMeleeDamage(Data.of("bigtick.damage") * damageModifier, global_position, self)
	InputSystem.shake(40, 0.3, 8, global_position)

func animateDeath():
	$DieSound.play()
	animation("die")
