extends Carryable

enum State {WORKING, FALLING, SLEEPING, SCARED, CARRIED, LANDING}
var state:int = State.SLEEPING

var cooldown := 0.0
var hitCooldown := 0.0
var direction:Vector2 = Vector2.LEFT
var stableTime := 0.0
var stuckTime := 0.0
var sparkCooldown := -1.0
var remainingSleepTime := 0.0
var wasGoingDown := false
var currentDrillSound
var stepSounds:Array

var isOnScreen := false
var arrowsByRequester := {}

var remainingHits := 0
var remainingBuffedHits := 0
var speed := 1.0
var hitStrengthMod := 1.0

var station

const FootstepDust = preload("res://content/gadgets/drillbot/FootstepDust.tscn")

# player controlled bits
var playerControlled:bool
var playerId:String
var moveDirectionInput:Vector2
var usables := []
var focussedUsable
var UseArea
var isInsideDome := false
var isInsideStation := false
var techId := "drillbot"
var drillDown := false

func _ready():
	super._ready()
	animation("sleep")
	state = State.SLEEPING
	normalMode()
	setDirection(Vector2.LEFT)
	
	if Data.ofOr("world.inversegravity", false):
		$BottomHitTestRay.rotate(PI)
		$Sprite2D.flip_v = true
		$Sprite2D.position.y += 12
		$DrillHitTestRay.position.y += 5
	
	var drillbotCount := get_tree().get_nodes_in_group("drillbots").size()
	if GameWorld.isChristmas and drillbotCount == 1:
		$Sprite2D.sprite_frames = load("res://content/gadgets/drillbot/frames_christmas.tres")
	else:
		$Sprite2D.sprite_frames = load("res://content/gadgets/drillbot/frames" + str(1 + (drillbotCount - 1) % 4) + ".tres")
	
	if GameWorld.isChristmas:
		$StepSound.pitch_scale = 1.0
		$StepSound.basePitch = 1.0
		$StepSound.streams = [
			preload("res://content/sounds/christmas/belldig_01.wav"),
			preload("res://content/sounds/christmas/belldig_02.wav"),
			preload("res://content/sounds/christmas/belldig_03.wav"),
			preload("res://content/sounds/christmas/belldig_04.wav"),
			preload("res://content/sounds/christmas/belldig_05.wav"),
		]

	stepSounds = [$StepSound]

	Data.listen(self, "monsters.wavepresent")
	Data.listen(self, "drillbot.drilllevel", true)
	Data.listen(self, "drillbot.amount", true)
	Style.init(self)
	
	Level.addTutorial(self, "drillbothandling")
	Level.addTutorial(self, "drillbotsleeping")
	
	Achievements.addIfOpen(self, "DRILLBERT_TREATS")

func serialize()->Dictionary:
	var data = super.serialize()
	data["state"] = state
	data["cooldown"] = cooldown
	data["hitCooldown"] = hitCooldown
	data["direction"] = var_to_str(direction)
	data["stableTime"] = stableTime
	data["stuckTime"] = stuckTime
	data["remainingSleepTime"] = remainingSleepTime
	data["wasGoingDown"] = wasGoingDown
	data["remainingHits"] = remainingHits
	data["remainingBuffedHits"] = remainingBuffedHits
	data["speed"] = speed
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	cooldown = data["cooldown"]
	hitCooldown = data["hitCooldown"]
	stableTime = data["stableTime"]
	stuckTime = data["stuckTime"]
	remainingSleepTime = data["remainingSleepTime"]
	wasGoingDown = data["wasGoingDown"]
	speed = data["speed"]

	setState(int(data["state"]))
	setDirection(BackwardCompatibilityUtils.str_to_var(data["direction"]))
	
	if state == State.WORKING:
		normalMode()
		startWorking()
	if state == State.FALLING:
		normalMode()
		startFalling()
	if state == State.SLEEPING:
		normalMode()
	if state == State.SCARED:
		normalMode()
	if state == State.CARRIED:
		onCarried(carriedBy[0])
	if state == State.LANDING:
		pass

	await GameWorld.savegame_loaded
	
	remainingHits = data["remainingHits"]
	remainingBuffedHits = data["remainingBuffedHits"]

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"drillbot.drilllevel":
			match int(newValue):
				0: currentDrillSound = $DrillSound0
				1: currentDrillSound = $DrillSound1
				2: currentDrillSound = $DrillSound2
				3: currentDrillSound = $DrillSound3
				4: currentDrillSound = $DrillSound4
				_: currentDrillSound = $DrillSound0
		"monsters.wavepresent":
			if not newValue and carriedBy.size() == 0:
				stopBeingScared()
		"drillbot.amount":
			if oldValue:
				remainingHits = remainingHits + (newValue - oldValue)
			else:
				remainingHits += newValue

func _physics_process(delta):
	for req in arrowsByRequester:
		var arrow = arrowsByRequester[req]
		arrow.visible = not isOnScreen
		var basePos = req.global_position
		var d = global_position - basePos
		arrow.rotation = d.angle() + PI * 0.5
		arrow.position = basePos + Vector2.UP.rotated(arrow.rotation) * 35
	
	if isCarried():
		rotateUpright()
		return
	
	if isPlane():
		stableTime += delta
	else:
		if not state == State.FALLING:
			if stableTime > 0.0:
				stableTime = 0.0
			stableTime -= delta
			if stableTime < -0.3:
				startFalling()
	
	if cooldown > 0.0:
		cooldown -= delta * GameWorld.cycleSpeed
		return
	
	if GameWorld.softPaused() and not playerControlled:
		if state == State.WORKING:
			if Data.of("monsters.wavepresent") and beScared():
				return
	
	$DrillHitTestRay.enabled = true
	match int(state):
		State.WORKING:
			rotateUpright()
			if linear_velocity.y > 2.0 and stableTime <= -0.3 and gravity_scale >= 0.2:
				startFalling()
				return
			
			if hitCooldown > 0.0:
				hitCooldown -= delta
				if sparkCooldown > 0.0:
					sparkCooldown -= delta
				if sparkCooldown <= 0.0 and sparkCooldown > -1:
					for _i in range(1):
						var s = Data.KEEPER_SPARK.instantiate()
						if $DefaultCollisionShape3.disabled:
							s.global_position = $DrillHitTestRay.get_collision_point()
						else:
							s.global_position = $DrillPoint.global_position
						s.apply_central_impulse(Vector2.LEFT.rotated($DrillHitTestRay.rotation+randf_range(-0.5,0.5))*randf_range(30,150))
						get_parent().call_deferred("add_child", s)
					sparkCooldown = 0.03 * (1.0 / speed)

			var collider
			if drillDown:
				collider = $BottomHitTestRay.get_collider()
			else:
				collider = $DrillHitTestRay.get_collider()
			if playerControlled:
				remainingHits = 999
				if moveDirectionInput.length() > 0:
					var s:float
					if collider and sign(moveDirectionInput.x) == sign(direction.x):
						s = moveDirectionInput.x * 2.0
					else:
						s = moveDirectionInput.x * 3.0 * speed
					apply_central_impulse(Vector2(s, moveDirectionInput.y * 3.0 * (1.0 - gravity_scale)))
				else:
					apply_central_impulse(Vector2(-linear_velocity.x * 0.2, 0))

			if not collider:
				if playerControlled:
					if linear_velocity.length() > 5.0:
						animation("walk")
						$Sprite2D.speed_scale = linear_velocity.length() / 50.0
						if linear_velocity.x < -1.0:
							setDirection(Vector2.LEFT)
						elif linear_velocity.x > 1.0:
							setDirection(Vector2.RIGHT)
					else:
						animation("idle")
				else:
					apply_central_impulse(direction * 2.0 * speed)
					animation("walk")
					$Sprite2D.speed_scale = linear_velocity.length() / 50.0
				stuckTime = 0.0
				if $DefaultCollisionShape3.disabled:
					$DefaultCollisionShape3.disabled = false
				return
			elif !Data.isDestructable(collider):
				animation("idle")
				stuckTime += delta
				if stuckTime > 1.0:
					if Data.of("drillbot.turnaround"):
						setDirection(direction * Vector2.LEFT)
					else:
						goToSleep()
			elif hitCooldown <= 0.0:
				if sparkCooldown == -1:
					sparkCooldown = 0
				if not playerControlled:
					apply_impulse(-linear_velocity * 0.5, Vector2(0,0))
				var dir = global_position - collider.global_position
				var ds = Data.of("drillbot.drillstrength")
				collider.hit(dir, ds + collider.max_health * 0.03 + ds * 0.005)
				animation("drill")
				currentDrillSound.play()
				if remainingBuffedHits > 0:
					remainingBuffedHits -= 1
					hitCooldown = 0.2 * (1.0 / speed)
				elif remainingHits > 0:
					remainingHits -= 1
					hitCooldown = 0.2
				elif not playerControlled:
					goToSleep()
		State.FALLING:
			if playerControlled:
				if moveDirectionInput.length() > 0:
					apply_central_impulse(Vector2(moveDirectionInput.x * 2.0, moveDirectionInput.y * 2.0 * (1.0 - gravity_scale)))
				else:
					apply_central_impulse(Vector2(-linear_velocity.x * 0.04, -linear_velocity.x * 0.04 * (1.0 - gravity_scale)))

			wasGoingDown = wasGoingDown or linear_velocity.y > 2.0
			if abs(linear_velocity.x) > 4.0:
				if linear_velocity.x < 0:
					setDirection(Vector2.LEFT)
				else:
					setDirection(Vector2.RIGHT)
			rotateUpright()
			if stableTime > 0.1 and wasGoingDown:
				animation("land")
				$LandSound.play()
				setState(State.LANDING)
			elif stableTime > 1.0 or (playerControlled and stableTime > 0.3):
				startWorking()
		State.SLEEPING:
			remainingSleepTime -= delta * GameWorld.cycleSpeed
			if remainingSleepTime <= 0.0:
				remainingHits = max(remainingHits, Data.of("drillbot.amount"))
				wakeUp()
			if linear_velocity.length() > 2.0:
				startFalling()
		State.LANDING:
			rotateUpright()
			if stableTime > (0.8 if playerControlled else 3.0):
				startWorking()

func isPlane() -> bool:
	return abs(fmod(rotation, PI)) <= 0.2 and abs(linear_velocity.y) * gravity_scale < 4.0  and $BottomHitTestRay.get_collider()

func rotateUpright():
	if playerControlled:
		apply_torque_impulse(-rotation * 20.0)
	else:
		apply_torque_impulse(-rotation * 10.0)

func startFalling(playSound := true):
	if $SleepingSound.playing:
		$SleepingSound.stop()
	if playSound:
		$FallingScreamSound.play()
	wasGoingDown = false
	setState(State.FALLING)
	stableTime = 0.0
	animation("knockback")
	$DefaultCollisionShape3.disabled = true

func animation(ani:String):
	$Sprite2D.speed_scale = 1.0 * speed
	$Sprite2D.play(ani) 

func startWorking():
	animation("idle")
	if not playerControlled:
		cooldown = 1.0
	setState(State.WORKING)

func isWorking():
	return state == State.WORKING

func isCarried():
	return state == State.CARRIED

func canFocusUse(keeper:Keeper) -> bool:
	return not isCarried() and not state == State.FALLING

func useHold(keeper:Keeper) -> bool:
	return false

func useHit(keeper:Keeper) -> bool:
	if state == State.SLEEPING:
		wakeUp()
		Backend.event("gadget_used", {"gadget": "drillbot", "activity": "woken"})
	elif state == State.SCARED:
		wakeUp()
	else:
		animation("idle")
		sparkCooldown = -1
		setDirection(direction * Vector2.LEFT)
		$ChangeDirectionSound.play()
		Backend.event("gadget_used", {"gadget": "drillbot", "activity": "switched"})
	remainingHits = Data.of("drillbot.amount")
	return true

func setDirection(dir:Vector2):
	if dir == direction:
		return
	
	direction = dir
	$Sprite2D.flip_h = dir == Vector2.RIGHT
	$DrillHitTestRay.rotation = direction.angle()
	$DrillHitTestRay.position.x *= -1
	$DrillPoint.position.x *= -1
	$Sprite2D.position.x *= -1
	$DefaultCollisionShape1.position.x *= -1
	$DefaultCollisionShape2.position.x *= -1
	$DefaultCollisionShape3.position.x *= -1
	$DefaultCollisionShape4.position.x *= -1
	$CarriedCollisionShape.position.x *= -1
	$FocusSprite.position.x *= -1
	$CarrySprite.position.x *= -1

func onCarried(p:Keeper):
	animation("carried")
	$DefaultCollisionShape1.disabled = true
	$DefaultCollisionShape2.disabled = true
	$DefaultCollisionShape3.disabled = true
	$DefaultCollisionShape4.disabled = true
	$CarriedCollisionShape.disabled = false
	setState(State.CARRIED)
	if $SleepingSound.playing:
		$SleepingSound.stop()
	remainingHits = Data.of("drillbot.amount")
	Backend.event("gadget_used", {"gadget": "drillbot", "activity": "pickup"})

func onDropped(p:Keeper):
	animation("knockback")
	normalMode()
	startFalling()
	Backend.event("gadget_used", {"gadget": "drillbot", "activity": "drop"})

func normalMode():
	$DefaultCollisionShape1.disabled = false
	$DefaultCollisionShape2.disabled = false
	$DefaultCollisionShape4.disabled = false
	$CarriedCollisionShape.disabled = true

func goToSleep():
	setState(State.SLEEPING)
	normalMode()
	animation("liedown")
	remainingSleepTime = Data.of("drillbot.sleeptime") * GameWorld.getTimeBetweenWaves()

func beScared():
	if Data.of("drillbot.scared"):
		setState(State.SCARED)
		normalMode()
		animation("scared")
		return true
	return false

func stopBeingScared():
	if state == State.SCARED:
		animation("getup")
		$WakeupSound.play()

func wakeUp():
	animation("getup")
	$SleepingSound.stop()
	$WakeupSound.play()
	remainingSleepTime = 0.0

func _on_sprite_2d_animation_looped() -> void:
	_SpriteAnimationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_SpriteAnimationFinishedCheck()

func _SpriteAnimationFinishedCheck() -> void:
	match $Sprite2D.animation:
		"getup":
			if remainingSleepTime <= 0:
				startWorking()
			else:
				goToSleep()
		"liedown":
			animation("sleep")
		"land":
			startWorking()

func setState(to):
	match int(state):
		State.FALLING:
			$FallingScreamSound.stop()
	state = to

func dropEntered(drop):
	if not drop.absorbed:
		drop.shred()

func dropExited(drop):
	pass

func dropTarget()->Vector2:
	return global_position

func _on_TreatArea_treat_eaten():
	if state == State.SLEEPING:
		wakeUp()
	remainingHits = Data.of("drillbot.amount") + Data.of("drillbot.buffextraamount")
	remainingBuffedHits = Data.of("drillbot.buffamount")
	speed = Data.of("drillbot.buffstrength")
	$TreatEatenSound.play()
	Backend.event("gadget_used", {"gadget": "drillbot", "activity": "treated"})

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "sleep" and $Sprite2D.frame == 14:
		$SleepingSound.play()
	elif $Sprite2D.animation == "walk" and $Sprite2D.frame%2 == 0:
		var d = FootstepDust.instantiate()
		if Level.viewports:
			Level.viewports.addElement(d)
		d.global_position = global_position
		d.flip_h = $Sprite2D.flip_h
		for sound in stepSounds:
			if not sound.playing:
				sound.play()
				return
		var sound = stepSounds.front().duplicate()
		add_child(sound)
		stepSounds.append(sound)
		sound.play()

# for tutorial
func getRemainingSleepTime() -> float:
	return remainingSleepTime

func _on_VisibilityNotifier2D_screen_entered():
	isOnScreen = true

func _on_VisibilityNotifier2D_screen_exited():
	isOnScreen = false

func showNavigationArrow(requester):
	if not arrowsByRequester.has(requester):
		addArrow(requester)

func hideNavigationArrow(requester):
	if arrowsByRequester.has(requester):
		eraseArrow(requester)

func addArrow(requester):
	var arrow = Sprite2D.new()
	arrow.texture = preload("res://content/gadgets/drillbot/arrow.png")
	arrow.z_index = 50
	get_parent().add_child(arrow)
	Style.init(arrow)
	arrowsByRequester[requester] = arrow

func eraseArrow(requester):
	arrowsByRequester[requester].queue_free()
	arrowsByRequester.erase(requester)

func asPlayerControlled():
	if playerControlled:
		return
	playerControlled = true
	hitStrengthMod = 2.0
	add_to_group("secondary-keeper")

func jump():
	if isPlane():
		apply_central_impulse(Vector2.UP * 280 * gravity_scale)
	return true

func setDrillDown(do):
	drillDown = do

func currentSpeed():
	return 100

func setSkin(skinId:String):
	$Sprite2D.sprite_frames = load("res://content/gadgets/drillbot/frames" + skinId + ".tres")

func unlockGadget(data):
	pass

func startInput():
	var i = preload("res://content/gadgets/drillbot/DrillbertInputProcessor.gd").new()
	i.keeper = self
	i.playerId = playerId
	i.deviceId = Keepers.getDeviceId(playerId)
	i.integrate(self)

func kill():
	remove()
	queue_free()

func remove():
	visible = false
