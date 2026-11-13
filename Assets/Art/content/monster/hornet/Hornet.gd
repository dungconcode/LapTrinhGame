extends "res://content/monster/Monster.gd"

enum Phase {ENTER, ATTACK, START_CHANGE_POSITION, CHANGE_POSITION, END_CHANGE_POSITION, DIE, IDLE}

var movePointProvider
var meleeTargetProvider
var nextMovementPositions := []
var currentMovementPositions := []
var currentMovementProgress := 0.0
var remainingStings := 0
var remainingFlyCycles := 0

var phase:int = Phase.ENTER
var averagedMoveDelta := 0.0
var movePauseTimer := 0.0

var movementNoise := FastNoiseLite.new()
var move_noise_time := randf() * 1000.0

var nextSide:String
var meleeTarget
var beforeAttack := true

@onready var sprite : AnimatedSprite2D = $Sprite2D


func init():
	movementNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	setFlip(position.x > 0)
	createMovementPositions(5, false)
	startMove()


func setProviders(movePointProvider, meleeTargetProvider, side:String):
	self.movePointProvider = movePointProvider
	self.meleeTargetProvider = meleeTargetProvider
	var spawnType = Data.of("hornet.spawnpoint") + "_" + side
	nextSide = side
	position = movePointProvider.getSpawn(spawnType).position

func startMove(delayMod := 1.0):
	movePauseTimer = delayMod * Data.stabilizedRandomFloat(0.6, 1.2, "hornetmove", 3.0)
	phase = Phase.START_CHANGE_POSITION
	var endPosition:Vector2 = nextMovementPositions.front()
	currentMovementPositions = [position, endPosition]
	currentMovementProgress = 0.0
	moveTween.interpolate_property(self, "currentMovementProgress", 0.0, -0.1, 0.1, Tween.TRANS_SINE, Tween.EASE_OUT)
	animation("change_position_start")

func endMove():
	sprite.rotation = 0.0
	phase = Phase.END_CHANGE_POSITION
	animation("change_position_end")
	nextMovementPositions.pop_front()

func executeMove():
	phase = Phase.CHANGE_POSITION
	beforeAttack = true
	
	$Sprite2D.speed_scale = speedModifier
	var duration : float = (position.distance_to(currentMovementPositions[1]) / (Data.of("hornet.speed") * speedModifier))*0.3
	moveTween.interpolate_property(self, "currentMovementProgress", -0.1, 1.0, duration, Tween.TRANS_SINE, Tween.EASE_OUT)
	moveTween.interpolate_callback(self, duration, "endMove")
	moveTween.start()
	
	phase = Phase.CHANGE_POSITION
	animation("change_position_loop")
	$StepSound.play()
	setFlip(nextSide == CONST.RIGHT)
	var dir_angle:float = currentMovementPositions[0].direction_to(currentMovementPositions[1]).angle()
	if sprite.flip_h:
		sprite.rotation = dir_angle - 2.6
	else:
		sprite.rotation = dir_angle - 0.7


func createMovementPositions(steps:int, switchSides:bool):
	meleeTarget = Level.dome.getMeleeTarget(nextSide).curve
	var fixedStingPos = find_child("StingPosition").position
	fixedStingPos.x *= -1 if switchSides else 1
	var targetPos:Vector2 = meleeTarget.sample_baked(meleeTarget.get_baked_length() * randf_range(0.5, 1.0)) + Vector2(4-randi()%8, 4-randi()%8) - fixedStingPos
	var dir:float = position.direction_to(targetPos).angle()
	if steps == 0:
		nextMovementPositions.append(targetPos)
	else:
		for i in steps:
			var nextPosition = lerp(position, targetPos, float(i+1)/float(steps))
			if i+1 < steps:
				nextPosition += Vector2.UP.rotated(dir)*randf_range(-40, 40)
			nextMovementPositions.append(nextPosition)


func onGameLost():
	if currentHealth > 0:
		phase = Phase.ENTER
		moveTween.stop_all()
		moveTween.remove_all()
		leaving = true
		setFlip(not sprite.flip_h)

func leave(delta:float):
	position.y -= delta * 30
	position.x += delta * position.x * 0.2
	animation("fly")

func startAttacking():
	beforeAttack = false
	$PrepareSound.play()
	remainingStings = Data.stabilizedRandomInt(3, 5, "hornetattacks", 10)
	phase = Phase.ATTACK
	if remainingStings > 1:
		animation("sting_quick")
	else:
		animation("sting")

func animateDeath():
	$DieSound.play()
	animation("die")
	phase = Phase.DIE

func subProcess(delta):
	if phase == Phase.ENTER:
		movePauseTimer -= delta
	elif phase == Phase.IDLE:
		movePauseTimer -= delta
		move_noise_time += delta * 6.0
		var noise = Vector2(movementNoise.get_noise_1d(move_noise_time), sin(move_noise_time))
		sprite.position = lerp(sprite.position, noise * 3.0, delta * 5.0)
	else:
		sprite.position = lerp(sprite.position, Vector2.ZERO, delta * 5.0)
	
	if phase == Phase.ENTER or phase == Phase.CHANGE_POSITION or phase == Phase.START_CHANGE_POSITION:
		var oldPos := position
		if not currentMovementPositions.is_empty():
			position = lerp(currentMovementPositions[0], currentMovementPositions[1], currentMovementProgress)
		if averagedMoveDelta == 0.0:
			averagedMoveDelta = (position - oldPos).length()
		else:
			averagedMoveDelta = averagedMoveDelta * (1.0 - delta) + (position - oldPos).length() * delta

func handleFullStun():
	animation("hit")

func stagger():
	animation("hit")

func resumeAfterStagger():
	match phase:
		Phase.ENTER:
			animation("fly")
		Phase.CHANGE_POSITION:
			currentMovementPositions[0] = position
			executeMove()
		_:
			remainingFlyCycles += 1
			phase = Phase.IDLE
			animation("fly")

func hitDome():
	remainingStings -= 1
	Level.dome.requestMeleeDamage(Data.of("hornet.damage") * damageModifier, $StingPosition.global_position, self)
	InputSystem.shake(40, 0.3, 8, $StingPosition.global_position)


func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()	

func _on_Sprite_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	if sprite.animation == "die":
		removeFreeBlocker()
	elif sprite.animation == "sting" or sprite.animation == "sting_quick":
		if remainingStings > 1:
			animation("sting_quick")
		elif remainingStings == 1:
			animation("sting")
		else:
			remainingFlyCycles = 1 + randi() % 2
			phase = Phase.IDLE
			animation("fly")
	elif sprite.animation == "fly" and phase == Phase.IDLE:
		if not nextMovementPositions.is_empty():
			if movePauseTimer <= 0.0:
				startMove()
		else:
			if remainingFlyCycles <= 0 and beforeAttack:
				startAttacking()
			elif remainingFlyCycles <= 0 and not beforeAttack:
				nextSide = CONST.LEFT if nextSide == CONST.RIGHT else CONST.RIGHT 
				createMovementPositions(1, true)
				startMove(0.2)
			else:
				remainingFlyCycles -= 1
	elif sprite.animation == "change_position_start":
		executeMove()
	elif sprite.animation == "change_position_end":
		phase = Phase.IDLE
		animation("fly")

func _on_Sprite_frame_changed():
	if sprite.animation == "sting":
		if sprite.frame == 6:
			hitDome()
			InputSystem.shake(Data.of("hornet.damage") * damageModifier, 0.1)
			$StingSound.play()
	elif sprite.animation == "sting_quick":
		if sprite.frame == 3:
			hitDome()
			InputSystem.shake(Data.of("hornet.damage") * damageModifier, 0.1)
			$StingSound.play()
