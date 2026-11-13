extends "res://content/monster/Monster.gd"

enum Phase {ANNOUNCE, DIVE, STICK, RETREAT, RISE, GO_TO_DIVE_POSITION, LEAVE, DIE_DIVE}

var phase:int = Phase.DIVE
var domeTarget
var target

var retreatPosition:Marker2D
var divePosition:Vector2

var cooldown := 0.0
var yDiff := 0

func init():
	position = divePosition
	$DeathFly.visible = false
	$DeathDive.visible = false
	$Sprite2D.play("dive")
	announce() # also updates hitboxes

func dive():
	phase = Phase.DIVE
	target = domeTarget
	if target.x < global_position.x:
		rotation = (target - global_position).angle() - 0.74*PI
	else:
		rotation = (target - global_position).angle() - 0.26*PI
	animation("dive")
	$DiveSound.play()
	setHittable(true)

func retreat():
	phase = Phase.RETREAT
	target = retreatPosition.global_position
	target.y += 50 - 100*randf()
	rotation = 0.0

func announce():
	setHittable(false)
	phase = Phase.ANNOUNCE
	cooldown = Data.of("diver.announcedelay")
	$AnnounceSound.play()
	var warner = preload("res://content/monster/diver/DiveWarner.tscn").instantiate()
	warner.process_material = warner.process_material.duplicate()
	get_parent().add_child(warner)
	(warner.process_material as ParticleProcessMaterial).color.r *= 3
	(warner.process_material as ParticleProcessMaterial).color.g *= 3
	(warner.process_material as ParticleProcessMaterial).color.b *= 3
	var d = domeTarget - global_position
	if domeTarget.x < global_position.x:
		warner.process_material.direction.x = d.x 
		warner.process_material.direction.y = d.y
	else:
		warner.process_material.direction.x = d.x 
		warner.process_material.direction.y = d.y 
	warner.position = global_position

func _process(delta: float) -> void:
	if phase == Phase.DIE_DIVE:
		move(Data.of("diver.divespeed") * 0.3, delta)

func subProcess(delta):
	setFlip(position.x > 0)
	
	match phase:
		Phase.ANNOUNCE:
			cooldown -= delta
			if cooldown <= 0.0:
				dive()
		Phase.DIVE:
			if not move(Data.of("diver.divespeed"), delta):
				animation("dive_in")
				applyDamage()
		Phase.RETREAT:
			if not move(Data.of("diver.retreatspeed") * speedModifier, delta):
				phase = Phase.RISE
				target.y = divePosition.y
				setHittable(false)
				yDiff = 0
		Phase.RISE:
			if not move(Data.of("diver.risespeed"), delta):
				phase = Phase.GO_TO_DIVE_POSITION
				target = divePosition
		Phase.GO_TO_DIVE_POSITION:
			if not move(Data.of("diver.retreatspeed"), delta):
				announce()

func resumeAfterStagger():
	match phase:
		Phase.DIVE:
			animation("dive")
		Phase.RETREAT:
			animation("fly")
		Phase.STICK:
			retreat()
			animation("fly")

func move(speed:float, delta:float):
	if target == null:
		return false
	var d = target - global_position
	var m = (d.normalized() * speed * delta).limit_length(d.length()) * $Sprite2D.speed_scale
	position += m
	return d.length() > 2.0

func applyDamage():
	Level.dome.requestMeleeDamage(Data.of("diver.damage") * damageModifier, global_position, self)
	InputSystem.shake(100, 0.2, 8, global_position)

func domeAcceptsDamage():
	# play hit sound, hit particles
	phase = Phase.STICK
	$ImpactSound.play()

func domeReflectsDamage(returnedDamage := 0.0, returnedSpeed := 1.0, damageModifier := 1.0, duration := 0.0):
	super.domeReflectsDamage(returnedDamage, returnedSpeed)
	retreat()
	animation("fly")

func domeAbsorbsDamage():
	retreat()
	animation("fly")

func leave(delta:float):
	position += delta * (retreatPosition.position - position).normalized() * 100.0 
	animation("fly")

func animateDeath():
	$DeathFly.flip_h = $Sprite2D.flip_h
	$DeathDive.flip_h = $Sprite2D.flip_h
	$Sprite2D.visible = false
	if phase == Phase.STICK or phase == Phase.RETREAT:
		$DeathFly.visible = true
		$DeathFly.play("default")
		$DieSoundFly.play()
	else:
		$DeathDive.visible = true
		$DeathDive.play("default")
		phase = Phase.DIE_DIVE
		$DieSoundDive.play()

func handleDamage():
	if phase == Phase.DIVE:
		receiveDamage = 999
	
func handleFullStun():
	animation("hit")

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	if $Sprite2D.animation == "dive_in":
		animation("dive_out")
		# move a little while flapping wings after getting unstuck
		moveTween.interpolate_property(self, "position", position, position + domeTarget*0.5, 1.2, Tween.TRANS_LINEAR, Tween.EASE_IN, 1.2)
		moveTween.interpolate_callback($RetreatSound, 0.9, "play")
		moveTween.start()
	elif $Sprite2D.animation == "dive_out":
		retreat()
		animation("fly")
	elif $Sprite2D.animation == "fly" and $Sprite2D.frame % 4 == 0:
		$FlapSound.play()

func _on_Death_animation_finished() -> void:
	super.removeFreeBlocker()


