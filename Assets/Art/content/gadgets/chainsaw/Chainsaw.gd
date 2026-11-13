extends SecondaryWeapon

var active := false
var minProgress := 0.05
var maxProgress := 0.95
var pathProbe:PathFollow2D

var direction:float

var cooldown:float
var stage := 1

func _ready():
	direction = -1.0 if randf() > 0.5 else 1.0
	$Sprite2D.play("idle_" + str(Data.of("chainsaw.stage")))
	%CutParticles.emitting = false
	
	Data.listen(self, "chainsaw.stage", true)
	Data.listen(self, "chainsaw.doublechainsaw", true)
	
	Style.init(self)

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"chainsaw.doublechainsaw":
			if newValue:
				if (maxProgress - minProgress) > 0.7:
					# means this chainsaw is probably covering the whole dome
					var otherChainsaw = load("res://content/gadgets/chainsaw/Chainsaw.tscn").instantiate()
					maxProgress = 0.47
					otherChainsaw.minProgress = 0.53
					var cupolaPath = get_parent()
					cupolaPath.add_child(otherChainsaw)
					otherChainsaw.init(cupolaPath) 
					pathProbe.progress_ratio = (maxProgress - minProgress) * 0.5
					otherChainsaw.pathProbe.progress_ratio = (otherChainsaw.maxProgress - otherChainsaw.minProgress) * 0.5
		"chainsaw.stage":
			stage = newValue
			match int(newValue):
				1:
					%MonsterHitboxCollisionShape2D.shape.radius = 10
					$Sprite2D.play(("run_slow" if active else "idle_") + str(newValue))
					%CutParticles.position = %edge_1.position
					%CutParticles.amount = 30
					#%CutParticles.lifetime = 0.15
				2: 
					%MonsterHitboxCollisionShape2D.shape.radius = 13
					$Sprite2D.play(("run_slow" if active else "idle_") + str(newValue))
					%CutParticles.position = %edge_2.position
					%CutParticles.amount = 50
					#%CutParticles.lifetime = 0.17
				3: 
					%MonsterHitboxCollisionShape2D.shape.radius = 15
					$Sprite2D.play(("run_slow" if active else "idle_") + str(newValue))
					%CutParticles.position = %edge_3.position
					%CutParticles.amount = 80
					#%CutParticles.lifetime = 0.2
				4: 
					%MonsterHitboxCollisionShape2D.shape.radius = 17
					$Sprite2D.play(("run_slow" if active else "idle_") + str(newValue))
					%CutParticles.position = %edge_4.position
					%CutParticles.amount = 120
					#%CutParticles.lifetime = 0.2

func init(cupulaPath:Path2D):
	stop()
	
	pathProbe = cupulaPath.createPathProbe(self)

func _physics_process(delta):
	if GameWorld.paused:
		return
	
	if playerControlled:
		if move.x != 0.0:
			var baseMoveSpeed = Data.of("chainsaw.speed") * 0.5
			if not $MoveSound.playing:
				$MoveSound.play()
			acceleration = clamp(acceleration + (5.0 - 2.0 * baseMoveSpeed) * delta, 0.0, 1.0)
			if Options.useGamepad:
				currentSpeed = baseMoveSpeed * pow(abs(move.x), 2.0) * sign(move.x)
			else:
				currentSpeed += (baseMoveSpeed * move.x - currentSpeed) * delta * 8.0 * acceleration
			pathProbe.moveBy(currentSpeed * delta)
			$MoveSound.play()
		else:
			$MoveSound.stop()
			currentSpeed = 0
			acceleration = 0
	else:
		if active:
			if not Data.of("monsters.wavepresent") or (not Keepers.oneInsideStation() and not Data.of("chainsaw.autonomy")):
				stop()
				return
		else:
			if Data.of("monsters.wavepresent") and (Keepers.oneInsideStation() or Data.of("chainsaw.autonomy")) and not GameWorld.gameover:
				start()
				return
		
		if not active:
			$Sprite2D.position.y = lerp($Sprite2D.position.y, -2.0, delta * 3)
			return
		
		if cooldown > 0.0:
			cooldown -= delta
			return
		
		var monsters = %MonsterHitbox.get_overlapping_areas()
		if monsters.is_empty():
			var farMonsters = $DistantMonsterChecker.get_overlapping_areas()
			$Sprite2D.speed_scale = 1.0
			%CutParticles.emitting = false
			if farMonsters.is_empty():
				$FireSound.stop()
				if $Sprite2D.position.y < -2.2:
					$Sprite2D.position.y = lerp($Sprite2D.position.y, -2.0, delta * 2)
				else:
					var speed = delta * direction * Data.of("chainsaw.speed")
					#speed *= pathProbe.getPathLengthModifier() not using that for now because it is more interesting
					pathProbe.progress_ratio = clamp(pathProbe.progress_ratio + speed, 0.0, 1.0)
					if ((pathProbe.progress_ratio <= minProgress and direction == -1) or (pathProbe.progress_ratio >= maxProgress and direction == 1)):
						change_direction()
			else:
				$Sprite2D.position.y = lerp($Sprite2D.position.y, $DistantMonsterChecker.position.y, delta * 2)
		else:
			if not $FireSound.shouldPlay:
				$FireSound.play()
				$ActivateSound.play()
			$Sprite2D.speed_scale = 2.0
			%CutParticles.emitting = true
			%CutParticles.rotation = 0.0 if pathProbe.progress_ratio <= 0.5 else PI
			
			if randf() < chunk_chance():
				spawn_larger_chunk()
			
			var center:Vector2
			var dmg = Data.of("chainsaw.damage")
			var stun = 0.3 * sqrt(dmg)
			for mon in monsters:
				mon.hit("chainsaw", dmg * delta, stun)
				center += mon.getHitboxCenter()
			center /= monsters.size()
			
			var curve:Curve2D = pathProbe.get_parent().curve
			var closeOffset = curve.get_closest_offset(center)
			pathProbe.progress = lerp(pathProbe.progress, closeOffset, delta * 1)
			
			if randf() > 1.0 - delta * 10:
				$Sprite2D.offset.x = randi_range(-1, 1)
				$Sprite2D.offset.y = randi_range(-1, 1)
				#pathProbe.progress += randf_range(-2, 2)
	
func change_direction():
	$ChangeDirectionSound.play()
	cooldown = 0.3
	direction = - direction

func start():
	$Sprite2D.play("run_slow" + str(Data.of("chainsaw.stage")))
	active = true

func stop():
	$StopSound.play()
	$MoveSound.stop()
	$FireSound.stop()
	$Sprite2D.play("run_slow" + str(Data.of("chainsaw.stage")))
	%CutParticles.emitting = false
	active = false

func chunk_chance():
	match stage:
		1:
			return 0.03
		2:
			return 0.06
	return 0.1

func spawn_larger_chunk():
	var new_slime = preload("res://content/effects/monster/SlimeExplosion.tscn").instantiate()
	new_slime.global_position =$Sprite2D.global_position # %edge_small.global_position if stage == 1 else (%edge_mid.global_position if stage == 2 else %edge_big.global_position)
	get_parent().add_child(new_slime)
	var dir = Vector2.RIGHT.rotated(%CutParticles.global_rotation)
	new_slime.apply_central_impulse(dir*randf_range(80, 240))

func _on_sprite_2d_animation_finished() -> void:
	if active:
		match $Sprite2D.animation:
			"run_slow1": $Sprite2D.play("run_1")
			"run_slow2": $Sprite2D.play("run_2")
			"run_slow3": $Sprite2D.play("run_3")
			"run_slow4": $Sprite2D.play("run_4")
	else:
		match $Sprite2D.animation:
			"run_slow1": $Sprite2D.play("idle_1")
			"run_slow2": $Sprite2D.play("idle_2")
			"run_slow3": $Sprite2D.play("idle_3")
			"run_slow4": $Sprite2D.play("idle_4")
