extends "res://content/monster/Monster.gd"

enum Phase {APPEAR, EMERGE, SHOOT, BURROW, DIE}

var phase:int = Phase.APPEAR
var projetileTargetProvider
var path:Path2D

var cooldown := 0.0
var didShoot := false

func init():
	$Sprite2D.play("appear")
	setHittable(false)
	global_position = path.curve.sample_baked(path.curve.get_baked_length() * randf_range(0.2,0.4)) + path.global_position
	setFlip(position.x > 0)

func subProcess(delta):
	if cooldown > 0.0:
		cooldown -= delta
		return
	
	match phase:
		Phase.APPEAR:
			cooldown = Data.stabilizedRandomFloat(2, 4, "wormappear", 4)
			phase = Phase.EMERGE
		Phase.EMERGE:
			animation("emerge")
			$EmergeSound.play()
			cooldown = Data.stabilizedRandomFloat(2, 4, "wormemerge", 4)
			phase = Phase.SHOOT
		Phase.SHOOT:
			animation("shoot")
			cooldown = Data.stabilizedRandomFloat(2, 4, "wormshoot", 4)
			didShoot = false
		Phase.BURROW:
			animation("burrow")
			$BurrowSound.play()
			cooldown = Data.stabilizedRandomFloat(3, 6, "wormburrow", 6)
			phase = Phase.EMERGE

func handleFullStun():
	animation("hit")

func stagger():
	animation("hit")

func resumeAfterStagger():
	cooldown = 0.0
	if didShoot and phase == Phase.SHOOT:
		phase = Phase.BURROW

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	match $Sprite2D.animation:
		"shoot":
			phase = Phase.BURROW
			animation("idle")
		"die":
			super.removeFreeBlocker()
		"emerge":
			animation("idle")

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "burrow" and $Sprite2D.frame == 9:
		setHittable(false)
	elif $Sprite2D.animation == "emerge" and $Sprite2D.frame == 4:
		setHittable(true)
	elif $Sprite2D.animation == "shoot" and $Sprite2D.frame == 7:
		var rock = preload("res://content/monster/worm/Rock.tscn").instantiate()
		rock.setFlip($Sprite2D.flip_h)
		rock.position = $RockSpawnPosition.position + position
		rock.target = projetileTargetProvider.getRandom(global_position)
		get_parent().add_child(rock)
		rock.damageSource = damageSource
		$SpitSound.play()
		didShoot = true

func leave(delta:float):
	if phase != Phase.DIE:
		phase = Phase.DIE
		animation("burrow")

func animateDeath():
	phase = Phase.DIE
	$DieSound.play()
	animation("die")

