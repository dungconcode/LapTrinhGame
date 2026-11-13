extends "res://content/monster/Monster.gd"

@export var distanceToMeleePoint := 10.0

var path:Path2D
var meleeTarget:Path2D
var walking := true
var progress := 0.0
var lastDelta:float

func init():
	position = path.curve.sample_baked(progress) + path.global_position
	var d = position.x - (path.curve.sample_baked(progress + 5).x + path.global_position.x)
	lastDelta = -d
	setFlip(d > 0.0)
	$Sprite2D.play("walk")
	updateHitboxState()
	$Sprite2D.frame = randi() % $Sprite2D.sprite_frames.get_frame_count("walk")

func subProcess(delta):
	if walking:
		progress += delta * Data.of("walker.speed") * $Sprite2D.speed_scale
		var cp = meleeTarget.curve.get_closest_point($HitPosition.global_position)
		if sign(lastDelta) != sign(cp.x - $HitPosition.global_position.x):
#			position = path.curve.sample_baked(targetProgress) + path.global_position
			animation("attack")
			walking = false
		else:
			position = path.curve.sample_baked(progress) + path.global_position

func leave(delta:float):
	if progress > 0.0:
		progress = max(0, progress - delta * Data.of("walker.speed") * $Sprite2D.speed_scale)
		position = path.curve.sample_baked(progress) + path.global_position

func onGameLost():
	if currentHealth > 0:
		leaving = true
		animation("walk")
		$Sprite2D.speed_scale = 0.9 + randf() * 0.5
		setFlip(not $Sprite2D.flip_h)

func stagger():
	animation("hit")

func resumeAfterStagger():
	if walking:
		animation("walk")
	else:
		animation("attack")

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()

func _on_Sprite_animation_finished():
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	if $Sprite2D.animation == "die":
		super.removeFreeBlocker()

func applyDamage():
	Level.dome.requestMeleeDamage(Data.of("walker.damage") * damageModifier, $HitPosition.global_position, self)
	InputSystem.shake(40, 0.3, 8, $HitPosition.global_position)
	$PunchSound1.play()
	$PunchSound2.play()
	$PunchSound3.play()

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "attack" and $Sprite2D.frame == 5:
		applyDamage()
#		var d = FootstepDust.instance()
#		add_child(d)
#		d.global_position = global_position + Vector2(0, 2)
#	elif $Sprite.animation == "walk" and ($Sprite.frame == 0 or $Sprite.frame == 4):
#		var d = FootstepDust.instance()
#		add_child(d)
#		d.global_position = global_position + Vector2(0, 2)

func animateDeath():
	animation("die")
	$DieSound.play()

