extends "res://content/monster/Monster.gd"

enum Phase {FALLING, APPEAR, BIRTH, IDLE, DIE, ARMOR}

var phase:int = Phase.FALLING
var path:Path2D
var nextProtectionHealthThreshold:float

var cooldown := 0.0
var cooldownFull := 1.0
var fallingSplatterTick := 0.0
var nextFallingSplatter := 0.05
var damageTakenMultiplier := 1.0

@onready var eggs := [$"%Eggs1", $"%Eggs2", $"%Eggs3"]
@onready var eggAttachers := [
	$EggAttacher1,
	$EggAttacher2,
	$EggAttacher3,
]
@onready var eggAttacherPositions := [
	$EggAttacher1.position,
	$EggAttacher2.position,
	$EggAttacher3.position,
]


func _ready():
	super._ready()
	for s in eggs:
		s.set_material($Sprite2D.material)


func init():
	animation("falling")
	var stabilizedFloatSpawnPos:float = Data.stabilizedRandomFloat(0.2, 0.6, "breeder", 1.0)
	var goalPos:Vector2 = path.curve.sample_baked(path.curve.get_baked_length() * stabilizedFloatSpawnPos) + path.global_position
	position = Vector2(goalPos.x + 10 - 20 * (randi() % 2), -550)
	$LaunchSound.play()
	$Sprite2D.rotation = position.direction_to(goalPos).angle()
	moveTween.interpolate_property(self, "position", position, goalPos, 1.0)
	moveTween.interpolate_callback(self, 1.0, "appear")
	moveTween.start()
	nextProtectionHealthThreshold = maxHealth * 0.7

func appear():
	spawnSlime(12)
	setFlip(position.x > 0)
	$Sprite2D.rotation = 0.0
	animation("appear")
	$LandSound.play()
	phase = Phase.APPEAR

func spawnSlime(amount, rotationRange:=0.9, color:=Color("#0006B4"), pos:=position):
	for i in amount:
		var new_slime = preload("res://content/effects/monster/SlimeExplosion.tscn").instantiate()
		new_slime.styleColor = color
		new_slime.position = pos
		get_parent().add_child(new_slime)
		new_slime.apply_central_impulse(Vector2.UP.rotated(randf_range(-rotationRange, rotationRange))*randf_range(80, 240))

func spawnTicks():
	$BirthSound.play()
	spawnSlime(24, 0.8, Color("#0006B4"), $TickSpawnPosition.position+position)
	spawnSlime(6, 0.6, Color("#10ECB4"), $TickSpawnPosition.position+position)
	for e in eggs:
		e.hide()
		
	if Level.monsters.disabled: #don't spawn after the relic exploded
		return
		
	for i in Data.stabilizedRandomInt(Data.of("breeder.minspawn"), Data.of("breeder.maxspawn"), "breederspawn", 6):
		var variant = "left" if position.x < 0 else "right"
		var monster = preload("res://content/monster/tick/Tick.tscn").instantiate()
		monster.path = Level.world.assignRandomPath(Data.of("tick.movetype"), variant, monster)
		monster.target = Level.dome.getFrontAttackPosition(variant)
		monster.damageSource = "breeder"
		monster.phase = 0
		monster.headCount = 0
		monster.setFlip(position.x > 0)
		monster.throwTargetPos = monster.path.curve.get_closest_point(position)
		monster.progress = monster.path.curve.get_closest_offset(monster.throwTargetPos)
		monster.progress += randf_range(-50, 50)
		monster.throwTargetPos = monster.path.curve.sample_baked(monster.progress)
		monster.position = $TickSpawnPosition.position + position + Vector2(randf_range(-6, 6), randf_range(-6, 6))
		Level.monsters.registerMonster(monster)

func subProcess(delta):
	if phase == Phase.FALLING:
		if fallingSplatterTick >= nextFallingSplatter:
			spawnSlime(randi() % 2 + 1, 0.5)
			fallingSplatterTick = 0.0
			nextFallingSplatter = randf_range(0.05, 0.1)
		else:
			fallingSplatterTick += delta
		
	if currentHealth <= nextProtectionHealthThreshold and (phase == Phase.IDLE or phase == Phase.BIRTH):
		cooldown = 999
		for e in eggs:
			e.hide()
		spawnSlime(8, 0.8, Color("#0006B4"), $TickSpawnPosition.position+position)
		spawnSlime(5, 0.6, Color("#10ECB4"), $TickSpawnPosition.position+position)
		animation("armor_up")
		$ArmorUpSound.play()
		phase = Phase.ARMOR
		damageTakenMultiplier = 0.2
		nextProtectionHealthThreshold = -1
	
	if cooldown > 0.0:
		if phase == Phase.IDLE:
			for e in eggs:
				e.size = abs(1.0 - cooldown / cooldownFull) * 0.7
				e.violence = ease(abs(1.0 - cooldown / cooldownFull), 4.5) * 15.0
				e.show()
			for i in eggAttachers.size():
				eggAttachers[i].position.y = eggAttacherPositions[i].y - abs(cooldownFull-cooldown) * 3.0
			animation("idle")
		cooldown -= delta * stunLevel()
		return
	
	match phase:
		Phase.IDLE:
			cooldown = 999
			animation("birth")
			phase = Phase.BIRTH
		Phase.ARMOR:
			cooldown = 999
			$ArmorDownSound.play()
			animation("armor_down")

func animateDeath():
	for e in eggs:
		e.hide()
	spawnSlime(14, 0.8, Color("#0006B4"), Vector2(0.0, -5.0)+position)
	spawnSlime(14, 0.6, Color("#10ECB4"), Vector2(0.0, -5.0)+position)
	$DieSound.play()
	animation("die")
	phase = Phase.DIE

func handleFullStun():
	animation("hit")

func stagger():
	animation("hit")

func resumeAfterStagger():
	if phase == Phase.IDLE:
		animation("idle")
	elif phase == Phase.BIRTH:
		animation("idle")
		phase = Phase.IDLE
		cooldown += 5.0

func hit(source:String, damage:float, stun:float, immediateStun := false):
	super.hit(source, damage * damageTakenMultiplier, stun, immediateStun)

func _on_sprite_2d_animation_looped() -> void:
	_animationFinishedCheck()	

func _on_Sprite_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	if $Sprite2D.animation == "appear":
		animation("idle")
		phase = Phase.IDLE
		cooldownFull = Data.stabilizedRandomFloat(3, 5, "breeederidle", 5)
		cooldown = cooldownFull
	elif $Sprite2D.animation == "birth":
		animation("idle")
		phase = Phase.IDLE
		cooldownFull = Data.stabilizedRandomFloat(3, 5, "breeederbirth", 5)
		cooldown = cooldownFull
	elif $Sprite2D.animation == "armor_up":
		animation("armor")
		cooldownFull = Data.stabilizedRandomFloat(8, 14, "breeederarmor", 14)
		cooldown = cooldownFull
	elif $Sprite2D.animation == "armor_down":
		phase = Phase.IDLE
		animation("idle")
		cooldownFull = Data.stabilizedRandomFloat(3, 5, "breeederidle", 5)
		cooldown = cooldownFull
		damageTakenMultiplier = 1.0
	elif $Sprite2D.animation == "die":
		removeFreeBlocker()

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "appear" and $Sprite2D.frame == 9:
		setHittable(true)
	elif $Sprite2D.animation == "birth" and $Sprite2D.frame == 4:
		spawnTicks()
	elif $Sprite2D.animation == "armor_down" and $Sprite2D.frame == 1:
		damageTakenMultiplier = 1.0
		$ArmorDownSound.play()
	elif $Sprite2D.animation == "armor_down" and $Sprite2D.frame == 1:
		$ArmorUpSound.play()


