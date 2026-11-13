extends "res://content/monster/Monster.gd"

signal move_finished

enum Phase {SHOOT, TELEPORT, DIE}

var projetileTargetProvider
var movePointProvider
var phase:int
var cooldown := 0.0
var nextSide:String
var teleportsLeft:int

func init():
	teleportsLeft = Data.stabilizedRandomInt(2, 3, "shifterteleportations", 4)
	finishTeleport()

func setProviders(movePointProvider, projetileTargetProvider, side:String):
	self.movePointProvider = movePointProvider
	self.projetileTargetProvider = projetileTargetProvider
	var spawnType = Data.of("shifter.spawnpoint") + "_" + side
	position = movePointProvider.getSpawn(spawnType).position
	nextSide = side

func subProcess(delta):
	if cooldown > 0.0:
		cooldown -= delta
		return
	
	match phase:
		Phase.SHOOT:
			pass
		Phase.TELEPORT:
			pass

func leave(delta:float):
	pass

func onGameLost():
	if currentHealth > 0:
		leaving = true
		animation("teleport_start")

func handleFullStun():
	animation("hit")

func stagger():
	$Sprite2D.play("hit")

func resumeAfterStagger():
	startTeleport()

func startTeleport():
	animation("teleport_start")
	phase = Phase.TELEPORT
	$TeleportAwaySound.play()

func finishTeleport():
	emit_signal("move_finished")
	animation("teleport_end")
	$TeleportAppearSound.play()
	
	position = movePointProvider.assignRandomPoint(nextSide, self).position
	lastPosition = position
	nextSide = CONST.LEFT if nextSide == CONST.RIGHT else CONST.RIGHT 
	setFlip(global_position.x > 0)
	teleportsLeft -= 1

func spawnShot():
	var p = preload("res://content/monster/shifter/ShifterProjectile.tscn").instantiate()
	p.damageSource = damageSource
	p.position = position + $ProjectilePosition.position
	p.origin = position
	p.target = projetileTargetProvider.getRandom(position) + Vector2(8-randi()%16, 8-randi()%16)
	p.damage = Data.of("shifter.damage") * damageModifier
	p.speed = Data.of("shifter.shotspeed")
	get_parent().add_child(p)
	$ShootSound.play()

func shoot():
	animation("shoot")
	$ChargingSound.play()
	phase = Phase.SHOOT

func animateDeath():
	$DieSound.play()
	animation("die")
	phase = Phase.DIE

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	match $Sprite2D.animation:
		"teleport_start":
			if leaving:
				removeFreeBlocker()
				removeFreeBlocker()
				visible = false
			else:
				finishTeleport()
		"die":
			removeFreeBlocker()
		"shoot":
			teleportsLeft = Data.stabilizedRandomInt(1, 3, "shifterteleportations", 4)
			startTeleport()
		"teleport_end":
			if teleportsLeft > 0:
				startTeleport()
			else:
				shoot()

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "shoot" and $Sprite2D.frame == 28:
		spawnShot()


