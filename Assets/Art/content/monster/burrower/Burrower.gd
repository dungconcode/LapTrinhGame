extends "res://content/monster/Monster.gd"


enum Phase {DROP, MOVE, BURROW, BURROWING, PUPATE, DIE, START_MOVING}


var phase:int = Phase.MOVE

var path:Path2D
var target:Vector2
var variant:String
var progress := 0.0
var dropTargetPos:Vector2
var moveBeforeBurrowDuration:float
var minDistanceToDome:float
var offset:Vector2
var speedScale:float
var peakRange := Vector2(70, 100)
var monsterWithin := "tick"
var distanceSinceLastSlimeDrop := randf()*20.0
var nextSlimeDropDist := 20.0
var lastPos := Vector2.ZERO
var eggGrowth := 0.0
var eggGrowthSpeed := randf_range(0.35, 0.55)

func init():
	if phase == Phase.DROP:
		animation("move")
		setFlip(dropTargetPos.x < position.x)
		var peakOffset := randf_range(peakRange.x, peakRange.y)
		var peakY := position.y - peakOffset
		var timeToPeak := peakOffset * 0.005 # 100 px in 0.5 s feels right
		var downDuration := 2.0
		moveTween.interpolate_property(self, "position:x", position.x, dropTargetPos.x, downDuration + timeToPeak, Tween.TRANS_LINEAR, Tween.EASE_IN)
		moveTween.interpolate_property(self, "position:y", position.y, peakY, timeToPeak, Tween.TRANS_QUAD, Tween.EASE_OUT)
		moveTween.interpolate_property(self, "position:y", peakY, dropTargetPos.y + offset.y, downDuration, Tween.TRANS_QUAD, Tween.EASE_IN, timeToPeak)
		moveTween.interpolate_callback(self, 0.5, "setFlip", position.x > 0)
		moveTween.interpolate_callback(self, 2.0, "hitGround")
		moveTween.start()
	else:
		startMoving()
		moveBeforeBurrowDuration = 9999
		offset = Vector2(0, randf_range(-5, 5))
		variant = CONST.LEFT if position.x < 0 else CONST.RIGHT
	speedScale = randf_range(0.8, 1.2)
	speedModifier *= speedScale
	minDistanceToDome = randf_range(180, 300)
	updateHitboxState()

func _ready():
	super._ready()
	$Egg.set_material($Sprite2D.material)

func subProcess(delta:float):
	match phase:
		Phase.DROP:
			var dropAngle:float = lastPos.direction_to(position).angle()
			$Sprite2D.rotation = dropAngle if not $Sprite2D.flip_h else dropAngle+PI
			distanceSinceLastSlimeDrop += position.distance_to(lastPos)
			if distanceSinceLastSlimeDrop >= nextSlimeDropDist:
				nextSlimeDropDist = randf_range(20.0, 80.0)
				distanceSinceLastSlimeDrop = 0.0
				spawnSlime(1)
			lastPos = position
		Phase.MOVE:
			progress += delta * Data.of("burrower.speed") * $Sprite2D.speed_scale
			moveBeforeBurrowDuration -= delta
			if abs(global_position.x) <= minDistanceToDome or moveBeforeBurrowDuration <= 0:
				phase = Phase.BURROW
			else:
				position = path.curve.sample_baked(progress) + path.global_position + offset
		Phase.BURROW:
			phase = Phase.BURROWING
			$BurrowSound.play()
			animation("burrow")
		Phase.PUPATE:
			$Egg.show()
			eggGrowth += delta * eggGrowthSpeed
			if eggGrowth >= 0.7:
				var rotMin:float = -0.4 if position.x < 0 else -0.9
				var rotMax:float = 0.9 if position.x < 0 else 0.4
				spawnSlime(7, rotMin, rotMax, Color("#0006B4"), 70, 120, position, 4.0)
				spawnSlime(4, rotMin, rotMax, Color("#10ECB4"), 70, 180, position, 4.0)
				$Egg.hide()
				$ExplodeSound.play()
				$Sprite2D.hide()
				spawnMonster()
				removeFreeBlocker()
				die()
				phase = Phase.DIE
			else:
				$Egg.size = eggGrowth
		Phase.DIE:
			removeFreeBlocker()

func spawnSlime(amount, rotationMin:=-0.3, rotationMax:=0.3, color:=Color("#0006B4"), speed_min:=30.0, speed_max:=70.0, pos:=position, randPos:=0.0):
	for i in amount:
		var new_slime = preload("res://content/effects/monster/SlimeExplosion.tscn").instantiate()
		new_slime.styleColor = color
		new_slime.position = pos + Vector2.RIGHT.rotated(randf()*PI)*randPos
		get_parent().add_child(new_slime)
		new_slime.apply_central_impulse(Vector2.UP.rotated(randf_range(rotationMin, rotationMax))*randf_range(speed_min, speed_max))

func hitGround():
	$Sprite2D.rotation = 0.0
	$LandSound.play()
	if abs(global_position.x) <= minDistanceToDome or moveBeforeBurrowDuration <= 0:
		phase = Phase.BURROW
	else:
		startMoving()

func animateDeath():
	$Egg.hide()
	$Sprite2D.hide()
	spawnSlime(8, -0.7, 0.7, Color("#0006B4"), 70, 180, position, 6.0)
	$DieSound.play()
	removeFreeBlocker()

func startMoving():
	phase = Phase.MOVE
	$Sprite2D.rotation = 0.0
	animation("move")
	position = path.curve.sample_baked(progress) + path.global_position + offset
	var d = position.x - (path.curve.sample_baked(progress + 50).x + path.global_position.x)
	setFlip(d > 0.0)
	$Sprite2D.frame = randi() % $Sprite2D.sprite_frames.get_frame_count("move")
	spawnSlime(6, -0.8, 0.8, Color("#0006B4"), 60.0, 180.0)

func onGameLost():
	if currentHealth > 0:
		leaving = true
		if phase == Phase.MOVE:
			animation("move")
			$Sprite2D.speed_scale = 0.9 + randf() * 0.5
			setFlip(not $Sprite2D.flip_h)
		else:
			if not dead:
				die()
				animateDeath()
				phase = Phase.DIE

func leave(delta:float):
	if phase == Phase.MOVE:
		if $Sprite2D.flip_h:
			position.x -= Data.of("burrower.speed") * delta
		else:
			position.x += Data.of("burrower.speed") * delta

func _on_Sprite_animation_finished():
	match $Sprite2D.animation:
		"burrow":
			animation("pupate")
			phase = Phase.PUPATE
		"die":
			removeFreeBlocker()
			die()
			phase = Phase.DIE

func spawnMonster():
	var monster
	var spawned := []
	match monsterWithin:
		"mucker":
			monster = preload("res://content/monster/mucker/Mucker.tscn").instantiate()
			Level.world.assignPathOccupation(Data.of("mucker.movetype"), path, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
			spawned.append(monster)
		"walker":
			monster = preload("res://content/monster/walker/Walker.tscn").instantiate()
			Level.world.assignPathOccupation(Data.of("walker.movetype"), path, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
			spawned.append(monster)
		"rockman":
			monster = preload("res://content/monster/rockman/Rockman.tscn").instantiate()
			Level.world.assignPathOccupation(Data.of("rockman.movetype"), path, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
			spawned.append(monster)
		"tick":
			var count : int = Data.stabilizedRandomInt(3, 4, "bloater.ticks", 2)
			for i in count:
				monster = preload("res://content/monster/tick/Tick.tscn").instantiate()
				Level.world.assignPathOccupation(Data.of("tick.movetype"), path, monster)
				monster.target = Level.dome.getFrontAttackPosition(variant)
				monster.headCount = 1.0 / float(count)
				spawned.append(monster)
		"bigtick":
			var count : int = Data.stabilizedRandomInt(1, 3, "bloater.bigticks", 2)
			for i in count:
				monster = preload("res://content/monster/bigtick/Bigticker.tscn").instantiate()
				Level.world.assignPathOccupation(Data.of("bigtick.movetype"), path, monster)
				monster.target = Level.dome.getFrontAttackPosition(variant)
				monster.headCount = 1.0 / float(count)
				spawned.append(monster)
		_:
			return
	for m in spawned:
		m.path = path
		m.progress = progress
		m.damageSource = damageSource
		Level.monsters.registerMonster(m)
	if monsterWithin == "bigtick": # needs to be set after registerMonster bc init() sets burrowProgress
		var pathBakedLength = path.curve.get_baked_length()
		for m in spawned:
			m.burrowProgress = progress + (0.1 + randf()* 0.4) * pathBakedLength

func _on_explode_sound_finished() -> void:
	removeFreeBlocker()
