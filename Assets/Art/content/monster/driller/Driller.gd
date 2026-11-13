extends "res://content/monster/Monster.gd"

const damageUnit := 2.0

var path:Path2D
var meleeTarget:Path2D
var phase := 0
var progress := 0.0

var damageSum := 0.0

var ground := true

func init():
	position = path.curve.sample_baked(0) + path.global_position
	var d = position.x - (path.curve.sample_baked(50).x + path.global_position.x)
	lastDelta = -d
	if d < 0.0:
		setFlip(true, true)
		$Particles1.process_material = preload("res://content/monster/driller/P1left.tres")
		$Particles2.process_material = preload("res://content/monster/driller/P2left.tres")
	else:
		$Particles1.process_material = preload("res://content/monster/driller/P1right.tres")
		$Particles2.process_material = preload("res://content/monster/driller/P2right.tres")
		
	$Sprite2D.play("walk")
	updateHitboxState()
	
var lastDelta:float
func subProcess(delta):
	if phase == 0:
		progress += delta * Data.of("driller.speed") * $Sprite2D.speed_scale
		var cp = meleeTarget.curve.get_closest_point($HitPosition.global_position)
		if sign(lastDelta) != sign(cp.x - $HitPosition.global_position.x):
			animation("settle")
			moveTween.interpolate_callback(InputSystem, 0.6, "shake", 100, 1.0, 32, global_position)
			moveTween.interpolate_callback($SettleSound, 0.6, "play")
			moveTween.start()
			phase = 1
		else:
			position = path.curve.sample_baked(progress) + path.global_position
	elif phase == 5:
		damageSum += Data.of("driller.damage") * delta
		if damageSum >= damageUnit:
			damageSum -= damageUnit
			Level.dome.requestMeleeDamage(damageUnit * damageModifier, $HitPosition.global_position, self)
			InputSystem.shake(20, 0.2, 8, global_position)

func leave(delta:float):
	pass

func onGameLost():
	animateDeath()

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()

func _on_Sprite_animation_finished():
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	if $Sprite2D.animation.begins_with("die_"):
		super.removeFreeBlocker()
	elif phase == 1:
		animation("attack_prepare")
		phase = 2
	elif phase == 2:
		animation("idle")
		phase = 3
	elif phase == 3:
		animation("attack_in")
		moveTween.interpolate_callback(InputSystem, 0.75, "shake", 100, 1.0, 32, global_position)
		moveTween.interpolate_callback($ImpactSound, 0.75, "play")
		moveTween.start()
		phase = 4
	elif phase == 4:
		phase = 5
		$Particles1.emitting = true
		$Particles2.emitting = true
		$PunchSound.play()
		animation("attack")

func _on_Sprite_frame_changed():
	pass
#	if $Sprite.animation == "walk" and $Sprite.frame % 2 == 0:
#		var d = FootstepDust.instance()
#		add_child(d)
#		d.set_size(1.0, 3.0)
#		d.global_position = global_position + Vector2(0, 2)

func animateDeath():
	$PunchSound.stop()
	if phase == 0:
		animation("die_walk")
	else:
		animation("die_attack")
	phase = 6
	$Particles1.emitting = false
	$Particles2.emitting = false
	$DieSound.play()
	$SettleSound.stop()

