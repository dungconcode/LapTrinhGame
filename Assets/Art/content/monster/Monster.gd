extends Area2D

signal died

#onready var IsHitSound:AudioStreamPlayer = find_node("IsHitSound")

@export var techId := ""
@export var autoAimShouldLeadShot := false
var tier:int
var stunPriority:int
var size:String

var counter:int
var damageSource:String

var invulnerable := false
var receiveDamage := 0.0
var timeSinceLastShotAt := 0.0
var goalStunIntensity := 0.0
var minStunLevel:float
var stunIntensity := 0.0
var fullStunAt:float
var headCount := 1.0
var leaving := false
var dead := false
var stunned := false
var hitSoundPlayed := false
var inOriginalSpawnPlan := false

var damageSustainPerSecond := 0.0
var damageSustainSeconds := 0.0
var stunSustainSeconds := 0.0
var stunSustainLevel := 0.0

var currentHealth:float
var maxHealth:float
var currentStaggerDuration:float

var attackTween:DeprecatedTween
var moveTween:DeprecatedTween

var hitBoxes := {}
var hittable := true
var shouldUpdateHitbox := true
var hitboxToDisable := []
var hitboxToEnable := []

var outline_frames = 0

var remainingFreeBlockers := 2

var speedModifier:float
var damageModifier:float

var centerPosition:Vector2
var linear_velocity:Vector2
var lastPosition:Vector2

func _ready():
	tier = Data.of(techId + ".tier")
	size = Data.of(techId + ".size")
	speedModifier = Data.ofOr("monstermodifiers.move_speed", 1.0)
	damageModifier = Data.ofOr("monstermodifiers.damage", 1.0)
	
	fullStunAt = Data.of(techId+".fullStunThreshold")
	stunPriority = Data.of(techId + ".stunpriority")
	minStunLevel = Data.ofOr(techId + ".minStunLevel", 0.0)
	
	$Sprite2D.material = $Sprite2D.material.duplicate()
	$Sprite2D.material.set_shader_parameter("flash_rate", 0.0)
	$Sprite2D.material.set_shader_parameter("flash_magnitude", 0.0)
	
	damageSource = techId
	currentHealth = Data.of(techId+".health") * Data.of("monstermodifiers.health")
	maxHealth = currentHealth
	currentStaggerDuration = 0.0
	
	attackTween = DeprecatedTween.new()
	add_child(attackTween)
	moveTween = DeprecatedTween.new()
	add_child(moveTween)
	
	$Sprite2D.speed_scale = speedModifier
	moveTween.playback_speed = $Sprite2D.speed_scale 
	
	add_to_group("lostL")
	
	var regex = RegEx.new()
	regex.compile("\\D*")
	for c in get_children():
		if c.name.begins_with("Hitbox"):
			var m = regex.search(c.name.substr(6))
			var key = m.strings[0].to_lower()
			var arr = hitBoxes.get(key, [])
			arr.append(c)
			hitBoxes[key] = arr
		elif c.name.begins_with("DieSound"):
			c.connect("finished", Callable(self, "removeFreeBlocker"))
	
	init()
	updateHitboxState()
	lastPosition = position
	
	Style.init(self)

func init():
	pass

func setFlip(newFlip:bool, force := false):
	if $Sprite2D.flip_h == newFlip and not force:
		return
	
	$Sprite2D.flip_h = newFlip
	# monster is not centered in sprite, so switch the position a bit to fix the transition
	for c in get_children():
		if c is Node2D:
			c.position.x = -c.position.x
			c.rotation = -c.rotation
		if c is Sprite2D or c is AnimatedSprite2D:
			c.flip_h = newFlip
		if c is CollisionPolygon2D:
			for i in range(0, c.polygon.size()):
				c.polygon[i].x *= -1

func animation(n:String):
	var previous = $Sprite2D.animation
	$Sprite2D.play(n)
	
	if n != previous:
		updateHitboxState()

func setHittable(do:bool):
	if hittable == do:
		return
	hittable = do
	updateHitboxState()

func updateHitboxState():
	shouldUpdateHitbox = true
	if hittable:
		hitboxToDisable.clear()
		hitboxToEnable.clear()
		
		var goalHitbox:String = ""
		if hitBoxes.has($Sprite2D.animation):
			goalHitbox = $Sprite2D.animation
		elif hitBoxes.has("default"):
			goalHitbox = "default"
		
		for c in hitBoxes:
			if c == goalHitbox:
				for hb in hitBoxes[c]:
					centerPosition = hb.position
					if hb.disabled:
						hitboxToEnable.append(hb)
			else:
				for hb in hitBoxes[c]:
					if not hb.disabled:
						hitboxToDisable.append(hb)
	else:
		hitboxToEnable.clear()
		for c in hitBoxes:
			for hb in hitBoxes[c]:
				if not hb.disabled:
					hitboxToDisable.append(hb)

func _physics_process(delta):
	outline_frames -= 1
	if outline_frames == 0:
		$Sprite2D.material.set_shader_parameter("outline", false)
	
	linear_velocity = lerp(linear_velocity, (position - lastPosition) / delta, delta * 10.0)
	lastPosition = position
	
	if hitboxToEnable.size() > 0:
		for h in hitboxToEnable:
			hitboxToDisable.erase(h)
			h.disabled = false
		hitboxToEnable.clear()
	elif hitboxToDisable.size() > 0:
		for h in hitboxToDisable:
			h.disabled = true
		hitboxToDisable.clear()
	
	if dead:
		if remainingFreeBlockers <= 0:
			queue_free()
			# don't trigger again
			remainingFreeBlockers = 9999
		return
	
	if currentHealth <= 0 or GameWorld.paused:
		$Sprite2D.material.set_shader_parameter("flash_magnitude", 0.0)
		return
	
	if leaving:
		leave(delta)
		$Sprite2D.material.set_shader_parameter("flash_magnitude", 0.0)
		return
	
	if invulnerable:
		stunIntensity = 0.0
	
	if damageSustainSeconds > 0.0:
		damageSustainSeconds -= delta
		receiveDamage += delta * damageSustainPerSecond
	
	var currentStunLevel = stunLevel()
	
	if currentStunLevel <= 0.0:
		stunIntensity = fullStunAt
		# to play hit animations properly
		$Sprite2D.speed_scale = 1.0
		$Sprite2D.material.set_shader_parameter("flash_rate", 0)
		$Sprite2D.material.set_shader_parameter("flash_magnitude", 0)
		moveTween.playback_speed = 1.0
		if not stunned:
			stunned = true
			handleFullStun()
	else:
		stunned = false
		$Sprite2D.speed_scale = currentStunLevel * speedModifier
		moveTween.playback_speed = $Sprite2D.speed_scale
		$Sprite2D.material.set_shader_parameter("flash_rate", 2.0)
		$Sprite2D.material.set_shader_parameter("flash_magnitude", (0.8 - 0.8 * currentStunLevel))
	stunIntensity += (goalStunIntensity - stunIntensity) * delta * 3.0
	
	var doSub := true
	if stunSustainSeconds > 0.0:
		stunSustainSeconds -= delta
		goalStunIntensity += (stunSustainLevel - goalStunIntensity) * delta * 5.0 
	else:
		if abs(goalStunIntensity) < 0.1:
			goalStunIntensity = 0.0
		else:
			goalStunIntensity *= (1.0 - delta * 10.0) 
	
	if receiveDamage > 0:
		timeSinceLastShotAt = 0.0
		if invulnerable:
			receiveDamage = 0.0
			stunIntensity = 0.0
		else:
			var damageTaken = receiveDamage * Data.of("monstermodifiers.damagetaken") * damageModifier
			if inOriginalSpawnPlan:
				Level.monsters.monsterLostHealth(min(damageTaken, currentHealth))
			currentHealth -= damageTaken
			receiveDamage = 0
#			if not hitSoundPlayed and IsHitSound:
#				IsHitSound.play()
#				hitSoundPlayed = true
			handleDamage()
			if currentHealth <= 0:
				die()
				animateDeath()
				return
	else:
		timeSinceLastShotAt += delta
	
	if currentStunLevel <= 0.0:
		currentStaggerDuration = 0.5 # TODO rework that thing
		attackTween.stop_all()
		moveTween.stop_all()
		doSub = false
	
	if currentStaggerDuration > 0:
		currentStaggerDuration -= delta
		if currentStaggerDuration <= 0:
			currentStaggerDuration = 0
			resumeAfterStagger()
			moveTween.resume_all()
			attackTween.resume_all()
		else:
			stagger()
			return
	
	if doSub:
		subProcess(delta)

func die():
	if dead:
		return
	
	$Sprite2D.speed_scale = 1.0
	emit_signal("died")
	moveTween.stop_all()
	moveTween.remove_all()
	attackTween.stop_all()
	attackTween.remove_all()
	setHittable(false)
	remove_from_group("monster")
	dead = true

func animateDeath():
	pass

func leave(delta:float):
	pass

func subProcess(delta:float):
	pass

func handleDamage():
	pass

func handleFullStun():
	pass

func stagger():
	pass

func resumeAfterStagger():
	pass

func onGameLost():
	if currentHealth > 0:
		leaving = true
		$Sprite2D.speed_scale = 1.0

func alive() -> bool:
	return currentHealth > 0.0

func aim(force := false):
	if not hittable and not force:
		return
	
	outline_frames = 2
	$Sprite2D.material.set_shader_parameter("outline", true)
	
func hit(source:String, damage:float, stun:float, immediateStun := false):
	if not hittable:
		return
	
	GameWorld.trackedDamageDealt[source] = GameWorld.trackedDamageDealt.get(source, 0) + damage
	receiveDamage += damage
	goalStunIntensity = max(stun, goalStunIntensity)
	if immediateStun:
		stunIntensity = goalStunIntensity

func pause():
	moveTween.stop_all()
	attackTween.stop_all()
	$Sprite2D.pause()

func unpause():
	moveTween.resume_all()
	attackTween.resume_all()
	$Sprite2D.play()

# contrary to popular believe, a low number indicates a high stun level (because the math gets easier this way)
func stunLevel() -> float:
	return clamp(1.0 - stunIntensity / fullStunAt, minStunLevel, 1.0)

func removeFreeBlocker():
	remainingFreeBlockers -= 1

func domeReflectsDamage(returnedDamage := 0.0, returnedSpeed := 1.0, damageModifier := 1.0, duration := 0.0):
	if returnedDamage > 0:
		if duration > 0.0:
			damageSustainSeconds = duration
			damageSustainPerSecond = returnedDamage / damageSustainSeconds
		else:
			receiveDamage += returnedDamage

func domeAcceptsDamage():
	pass

func domeAbsorbsDamage():
	pass

func applyTemporarySpeedChange(change:float, time:float = 0.0):
	speedModifier *= change
	
	if time == 0.0:
		return
	
	var t = Timer.new()
	add_child(t)
	t.connect("timeout", Callable(self, "applyTemporarySpeedChange").bind((1.0 /change) if change != 0.0 else speedModifier))
	t.connect("timeout", Callable(t, "queue_free"))
	t.start(time)

func canBeHit() -> bool:
	return hittable

func sustainStun(stunLevel:float, time:float):
	if not canBeHit():
		return
	
	hit("", 0, stunLevel, true)
	stunSustainSeconds = max(time, stunSustainSeconds)
	stunSustainLevel = stunLevel

func clearStun():
	goalStunIntensity = 0.0
	stunSustainSeconds = 0.0

func sustainDamage(dps:float, duration:float):
	if not hittable:
		return
	
	if damageSustainSeconds > 0.0:
		var totalDamage = damageSustainSeconds * damageSustainPerSecond + dps * duration
		damageSustainSeconds = duration
		damageSustainPerSecond = totalDamage / duration
	else:
		damageSustainSeconds = duration
		damageSustainPerSecond = dps

var intervalTimer
func sustainIntervalDamage(source:String, damage, stun, interval, times, delay := 0.0):
	if not canBeHit():
		return
	
	if times == 0:
		intervalTimer.queue_free()
		intervalTimer = null
		return
	
	if not intervalTimer:
		intervalTimer = Timer.new()
		intervalTimer.wait_time = delay
		add_child(intervalTimer)
	else:
		intervalTimer.wait_time = interval
		intervalTimer.disconnect("timeout", sustainIntervalDamage)
	
	intervalTimer.connect("timeout", sustainIntervalDamage.bind(source, damage, stun, interval, times - 1))
	if delay == 0.0:
		hit(source, damage, stun, true)
	
	intervalTimer.start()

func getCenter() -> Vector2:
	return centerPosition + global_position

func getSpriteSize() -> Vector2:
	var sprite = get_node("Sprite2D")
	if sprite == null:
		Logger.warn("Monster has no first-level literal Sprite2D node", "", self)
		return Vector2.ZERO
	var sprite_size = sprite.get_sprite_frames().get_frame(sprite.animation, 0).get_size()
	return sprite_size

func getHitboxCenter() -> Vector2:
	var hitPos:Vector2 = Vector2(0, 0)
	var i := 0.0
	for h in hitBoxes.values():
		for hitbox in h:
			if hitbox.disabled:
				continue
			hitPos += hitbox.position
			i += 1.0
	if i > 0:
		return global_position + hitPos / i
	else:
		return global_position
