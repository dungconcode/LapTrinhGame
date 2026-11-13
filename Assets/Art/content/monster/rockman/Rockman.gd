extends "res://content/monster/Monster.gd"

@export var distanceToMeleePoint := 10.0

enum State {WALK, STANDUP, ATTACK, DIE}

var state:int = State.WALK

var path:Path2D
var meleeTarget:Path2D
var attacking := false
var progress := 0.0
var targetProgress:float
var lastDelta:float

var initialPunchSpeed:float
var additionalPunchSpeed:float
var speedupTime:float
var currentAttackTime:float

func init():
	position = path.curve.sample_baked(0) + path.global_position
	var d = position.x - (path.curve.sample_baked(50).x + + path.global_position.x)
	lastDelta = -d
	setFlip(d > 0.0)
	$Sprite2D.play("walk")
	updateHitboxState()
	$Sprite2D.frame = randi() % $Sprite2D.sprite_frames.get_frame_count("walk")
	
	initialPunchSpeed = Data.of("rockman.initialPunchSpeed")
	additionalPunchSpeed = Data.of("rockman.additionalPunchSpeed")
	speedupTime = Data.of("rockman.speedupTime")

func subProcess(delta):
	match state:
		State.WALK:
			progress += delta * Data.of("rockman.speed") * $Sprite2D.speed_scale
			var cp = meleeTarget.curve.get_closest_point($HitPosition.global_position)
			if sign(lastDelta) != sign(cp.x - $HitPosition.global_position.x):
				animation("standup")
				state = State.STANDUP
			else:
				position = path.curve.sample_baked(progress) + path.global_position
		State.ATTACK:
			currentAttackTime += delta
			var progress = min(1.0, currentAttackTime / speedupTime)
			var speed = initialPunchSpeed + additionalPunchSpeed * progress
			$Sprite2D.speed_scale *= speed

func leave(delta:float):
		progress = max(0, progress - delta * Data.of("rockman.speed") * $Sprite2D.speed_scale)
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
	if state == State.WALK:
		animation("walk")
	elif state == State.ATTACK or state == State.STANDUP:
		animation("attack")

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()	

func _on_Sprite_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	if $Sprite2D.animation == "die":
		super.removeFreeBlocker()
	elif $Sprite2D.animation == "standup":
		animation("attack")
		state = State.ATTACK

func applyDamage():
	Level.dome.requestMeleeDamage(Data.of("rockman.damage") * damageModifier, $HitPosition.global_position, self)
	InputSystem.shake(40, 0.3, 8, $HitPosition.global_position)
	$PunchSound1.play()
	$PunchSound2.play()
	$PunchSound3.play()

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "attack" and $Sprite2D.frame == 9:
		applyDamage()
#	elif $Sprite.animation == "walk" and ($Sprite.frame == 0 or $Sprite.frame == 4):
#		var d = FootstepDust.instance()
#		add_child(d)
#		d.global_position = global_position + Vector2(0, 2)

func animateDeath():
	state = State.DIE
	animation("die")
	$DieSound.play()


