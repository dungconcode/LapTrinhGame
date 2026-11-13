extends RigidBody2D

var lifeTime:float
var timeAlive:float

var baseDamage:float
var damageDealt := 0.0
var damageModNextHit:float
var size := 1.0

var speedScale := 1.0

var maxSpeed:float
var bumpSpeedup := 30

var generation := 1
var hitCounter := 0
var removeBlockers := 2
var consecutiveIndestructibleHits := 0
var reflectCounter := 0
var consecutiveReflections := 0
var destroyed := false

var approachingBody

var is_paused := false

var playerId:String

var destroyTileCooldown := {}
var oldVelocity = Vector2()

func _ready():
	baseDamage = Data.of(playerId + ".keeper2.spherebasedamage")
	maxSpeed = Data.of(playerId + ".keeper2.spherespeed")
	lifeTime = Data.of(playerId + ".keeper2.spherebaselifetime") * size
	damageModNextHit = Data.of(playerId + ".keeper2.sphereadditionalfirsthitdamage")
	$Sprite2D.play("ready")
	$Trail.amount = 20
	$Trail.emitting = true
	Style.init($Sprite2D)
	linear_damp = 0.0
	
	$RayCastFront.enabled = true
	$Amb.play()
	
	pauseChanged()
	
	Achievements.addIfOpen(self, "KEEPER2_REFLECTIONS")
	Achievements.addIfOpen(self, "KEEPER2_SPHEREDURATION")

func serialize()->Dictionary:
	
	var data = {}
	data["meta.priority"] = 100
	data["meta.kind"] = "generic"
	data["linear_velocity"] = var_to_str(linear_velocity)
	data["oldVelocity"] = var_to_str(oldVelocity)
	data["lifeTime"] = lifeTime
	data["timeAlive"] = timeAlive
	data["baseDamage"] = baseDamage
	data["damageDealt"] = damageDealt
	data["damageModNextHit"] = damageModNextHit
	data["size"] = size
	data["speedScale"] = speedScale
	data["maxSpeed"] = maxSpeed
	data["bumpSpeedup"] = bumpSpeedup
	data["generation"] = generation
	data["hitCounter"] = hitCounter
	data["removeBlockers"] = removeBlockers
	data["consecutiveIndestructibleHits"] = consecutiveIndestructibleHits
	data["reflectCounter"] = reflectCounter
	data["consecutiveReflections"] = consecutiveReflections
	data["destroyed"] = destroyed
	data["is_paused"] = is_paused
	data["playerId"] = playerId
	
	var d := []
	for coord in destroyTileCooldown:
		var entry := [var_to_str(coord), var_to_str(destroyTileCooldown[coord][0]), var_to_str(destroyTileCooldown[coord][1])]
		d.append(entry)
	data["destroyTileCooldown"] = var_to_str(d)
	
	return data

func deserialize(data: Dictionary):
	linear_velocity = BackwardCompatibilityUtils.str_to_var(data["linear_velocity"])
	oldVelocity = BackwardCompatibilityUtils.str_to_var(data["oldVelocity"])
	lifeTime = data["lifeTime"]
	timeAlive = data["timeAlive"]
	baseDamage = data["baseDamage"]
	damageDealt = data["damageDealt"]
	damageModNextHit = data["damageModNextHit"]
	size = data["size"]
	speedScale = data["speedScale"]
	maxSpeed = data["maxSpeed"]
	bumpSpeedup = data["bumpSpeedup"]
	generation = data["generation"]
	hitCounter = data["hitCounter"]
	removeBlockers = data["removeBlockers"]
	consecutiveIndestructibleHits = data["consecutiveIndestructibleHits"]
	reflectCounter = data["reflectCounter"]
	consecutiveReflections = data["consecutiveReflections"]
	destroyed = data["destroyed"]
	is_paused = data["is_paused"]
	playerId = data["playerId"]
	
	var d:Array = str_to_var(data["destroyTileCooldown"])
	destroyTileCooldown = {}
	for entry in d:
		destroyTileCooldown[str_to_var(entry[0])] = [entry[1], str_to_var(entry[2])]
	pauseChanged()
	
	#pinball was saved during the destruction process, so we restart it
	if destroyed:
		destroyed = false
		destroy()

func _physics_process(delta):
	if GameWorld.paused or destroyed:
		return
	
	lifeTime = lifeTime - delta
	timeAlive += delta
	
	if lifeTime <= 0.0:
		linear_damp = 3.0
		$Trail.emitting = false
		if linear_velocity.length() <= 60.0:
			destroy()
			return
	
	for coord in destroyTileCooldown.keys().duplicate():
		var data:Array = destroyTileCooldown[coord]
		data[0] -= delta
		if data[0] <= 0.0:
			var otherTile = Level.map.getTile(Vector2i(coord))
			#prints("checking tile on ",coord, otherTile)
			if otherTile and Data.isDestructable(otherTile):
				var dir = data[1] - otherTile.coord
				if otherTile.type == "dirt":
					otherTile.hit(dir, otherTile.max_health)
					showHitEffect(otherTile, 1.0, false, dir * 0.5)
				else:
					otherTile.hit(dir, data[2] * 0.5)
			destroyTileCooldown.erase(coord)
	
	if $RayCastFront.enabled:
		var c = $RayCastFront.get_collider()
		if c:
			c.sphereApproaching(self)
			approachingBody = c
		elif approachingBody:
			approachingBody.spherePassed(self)
			approachingBody = null
	
	var speedScale = (linear_velocity.length() - 40) / 150.0
	var sizeScale = min(1.0, (0.6 + 1.0 * speedScale)) * min(size, 1.4)
	$Sprite2D.scale = Vector2.ONE * sizeScale
	$Trail.process_material.scale_min = sizeScale
	$Trail.process_material.scale_max = sizeScale
	$CollisionShape2D.shape.radius = 4.0
	$Sprite2D.modulate.r = 0.5 + speedScale * 0.5
	$Sprite2D.modulate.g = 0.25 + speedScale * 0.75
	$RayCastFront.rotation = linear_velocity.angle() - CONST.PI_HALF - rotation
	$RayCastFront.position = Vector2.DOWN.rotated($RayCastFront.rotation + PI) * 20

func reflect():
	if reflectCounter < 2:
		lifeTime += 0.5
	damageModNextHit = Data.of(playerId + ".keeper2.reflectnexthitdamage")
	var speedup = 1.0 + Data.of(playerId + ".keeper2.reflectspeed")
	var direction = -linear_velocity - linear_velocity.normalized() * maxSpeed * speedup
	apply_central_impulse(direction)
	$ReflectionBaseSound.play()
#	if damageModNextHit > 0.0:
#		$ReflectionMoreDamage.play()
#	if speedup > 1.0:
#		$ReflectionSpedUp.play()
	$Sprite2D.modulate.b = 0.0
	
	if reflectCounter > 0:
		consecutiveReflections += 1
	else:
		consecutiveReflections = 0
	reflectCounter = 2

func catch():
	linear_damp = 12
	$Sprite2D.play("vanish")
	$Sprite2D.frame = 0
	if approachingBody:
		approachingBody.spherePassed(self)
		approachingBody = null
	$RayCastFront.set_deferred("enabled", false)
	destroyed = true
	$SphereCatchSound.play()

func destroy():
	if destroyed:
		return
	
	linear_damp = 8
	$Sprite2D.play("vanish")
	$Sprite2D.frame = 0
	$VanishSound.play()
	if approachingBody:
		approachingBody.spherePassed(self)
		approachingBody = null
	$RayCastFront.set_deferred("enabled", false)
	destroyed = true

func _on_Pinball_body_entered(body):
	if not body or destroyed:
		return
	#this is possible when we collide the exact frame the game was paused
	if is_paused:
		return
	
	$Sprite2D.modulate.b = 1.0
	var velocity = linear_velocity.length()
	if velocity <= 20.0:
		destroy()
		return
	
	var dir = global_position - body.global_position
	var surface:Vector2
	if abs(dir.x) > abs(dir.y):
		surface = Vector2(0, linear_velocity.y)
	else:
		surface = Vector2(linear_velocity.x, 0)
	var steepnessMod = 1.0 - surface.normalized().dot(linear_velocity.normalized())
	if steepnessMod < 0.2:
		return
	
	var bs = getFreeBounceSound()
	if bs:
		bs.baseVolume = -6 + 6 * steepnessMod
		bs.play()
	
	var isDestructible = body.has_meta("destructable") and body.get_meta("destructable")
	
	if isDestructible:
		var damage = baseDamage + baseDamage * max(0, (velocity - 100))/100.0
#		damage = min(damage, body.health)
		damage += Data.of(playerId + ".keeper2.spherefractiondamage") * body.max_health
		damage = damage * steepnessMod * size
		var mod = 1.0 + damageModNextHit
		damageModNextHit *= 0.5
		damage *= mod
		hitCounter += 1
		
		body.hit(dir, damage)
		damageDealt += damage
		
		showHitEffect(body, clamp(velocity / 150.0, 0.25, 1), damageModNextHit > 0.2)
		
#		lifeTime = max(0.5 * steepnessMod, lifeTime + Data.of(playerId + ".keeper2.spherelifetimeperbounce") * steepnessMod)
		lifeTime = max(lifeTime, 0.5)
		consecutiveIndestructibleHits = 0
		if Data.of(playerId + ".keeper2.pinballdestroyadjacenttiles") and generation == 1:
			var tileDir:Vector2 = body.coord - Vector2(Level.map.getTileCoord(global_position))
			for offAngle in [CONST.PI_HALF, -CONST.PI_HALF]:
				var otherDir = tileDir.rotated(offAngle)
				var otherCoord = body.coord + otherDir
				if body.health <= 0:
					#for coord in Level.map.tiles:
						#prints(coord, coord is Vector2, coord is Vector2i, typeof(coord))
					#prints("checking for ", otherCoord, typeof(otherCoord), typeof(Vector2(otherCoord)), typeof(Vector2i(otherCoord)))
					#prints("tile dict has Vector2 coord ", Level.map.tiles.get(Vector2(otherCoord)), null)
					#prints("tile dict has Vector2i coord ", Level.map.tiles.get(Vector2i(otherCoord)), null)
					#prints(body.coord, tileDir, otherDir, otherCoord, Level.map.getTile(otherCoord), Level.map.getTile(Vector2i(otherCoord)))
					destroyTileCooldown[otherCoord] = [randf_range(0.05, 0.2), body.coord, damage]
				else:
					var otherTile = Level.map.getTile(otherCoord)
					if otherTile and otherTile.has_meta("destructable") and otherTile.get_meta("destructable"):
						otherTile.hit(body.coord - otherTile.coord, damage * 0.5)
	else:
		consecutiveIndestructibleHits += 1
	
	if consecutiveIndestructibleHits > 5:
		destroy()
	
	if linear_velocity.length() < maxSpeed * (1.0 + 0.5 * Data.of(playerId + ".keeper.drillBuff")):
		apply_central_impulse(linear_velocity.normalized() * bumpSpeedup * steepnessMod)
	
	reflectCounter -= 1

func showHitEffect(tile, pinballhit_scale, buffed, pos = global_position):
	var pinballhit = preload("res://content/keeper/keeper2/PinballHit.tscn").instantiate()
	Level.viewports.addElement(pinballhit)
	pinballhit.scale = Vector2(pinballhit_scale, pinballhit_scale)
	pinballhit.global_position = pos
	
	$TileHitSounds.hit(tile, buffed, false)

func getFreeBounceSound():
	if not $BounceSound1.playing:
		return $BounceSound1
	elif not $BounceSound2.playing:
		return $BounceSound2
	elif not $BounceSound3.playing:
		return $BounceSound3

func explode(explodingPlayerId:String):
	if destroyed:
		return
	var ex = load("res://content/keeper/keeper2/Explode.tscn").instantiate()
	ex.position = position
	ex.playerId = explodingPlayerId
	get_parent().add_child(ex)
	queue_free()

func _on_Sprite_animation_finished():
	if $Sprite2D.animation == "vanish":
		removeBlockerFreed()

func removeBlockerFreed():
	removeBlockers -= 1
	if removeBlockers <= 0:
		queue_free()

func pauseChanged():
	if GameWorld.paused:
		if not is_paused:
			oldVelocity = linear_velocity
			set_axis_velocity(Vector2.ZERO)
			freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
			freeze = true
			is_paused = true
	else:
		is_paused = false
		freeze = false
		set_axis_velocity(oldVelocity)
