extends Area2D

var showcaseMode := false
var currentMoveDirection:Vector2
var acceleration:float
var maxSpeed:float
var friction:float

var currentReticleExpansion := 12.0
var shotCharge := 0.0
var activation := 0.0
var polarFx : Node2D = null
var polarFxPerfectRing : Node2D = null
var polarFxPerfect : Node2D = null
var polarFxShotReady : Node2D = null
var active := false
var isPerfect := false
var quickshots := 0
var shotReadyScaleTween:Tween

@onready var autoAimArea = $AutoAimArea


func _ready():
	Data.listen(self, "tesla.reticlemaxspeed", true)
	Data.listen(self, "tesla.reticleacceleration", true)
	Data.listen(self, "tesla.reticlefriction", true)
	Data.listen(self, "tesla.autoaim", true)
	Data.listen(self, "tesla.shottype", true)


func activate():
	active = true
	if not polarFx:
		polarFx = preload("res://content/weapons/tesla/ReticlePolarFx.tscn").instantiate()
		polarFxPerfectRing = polarFx.get_node("PerfectTimeRing")
		polarFxPerfect = polarFx.get_node("PerfectTiming")
		polarFxShotReady = polarFx.get_node("Ready")
		Level.map.addPixelEffect(polarFx)
		connect("tree_exited", Callable(polarFx, "queue_free"))
	polarFx.setActive(true)


func deactivate():
	active = false
	isPerfect = false
	if polarFx:
		polarFx.setPower(0.0)
		polarFx.setActive(false)
	charge(false)


func _physics_process(delta):
	if active:
		modulate.a = min(modulate.a+delta*8.0, 1.0)
		arcFollowInner.show()
		arcFollowOuter.show()
		show()
	else:
		position = lerp(position, Vector2(0, -65.0), delta*remap(ease(modulate.a, 0.1), 0.01, 1.0, 6.0, 0.001))
		modulate.a = max(modulate.a-delta*0.5, 0.01)
		arcFollowInner.hide()
		arcFollowOuter.hide()
	updateVisual(delta)


func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"tesla.reticlemaxspeed":
			maxSpeed = newValue
		"tesla.reticleacceleration":
			acceleration = newValue
		"tesla.reticlefriction":
			friction = newValue
		"tesla.autoaim":
			autoAimArea.visible = newValue
			$AutoAimArea/CollisionShape2D.disabled = not newValue


func move(move:Vector2, delta:float):
	if not visible:
		return
	
	if Options.useGamepad or showcaseMode:
		currentMoveDirection = move
	elif Options.useMouseDomeGameplay:
		var dist_to_mouse = get_local_mouse_position().length()
		currentMoveDirection = get_local_mouse_position() * delta * dist_to_mouse
		currentMoveDirection = currentMoveDirection.limit_length(1.0)
	else:
		if move.length() == 0:
			currentMoveDirection *= 1.0 - delta * friction
		else:
			currentMoveDirection += move * acceleration * delta
			currentMoveDirection = currentMoveDirection.limit_length(1.0)
	
	position += currentMoveDirection * maxSpeed * delta * (1.0 - 0.6 * sqrt(max(0, 5.0 * (shotCharge - 0.8))))
	position.x = clamp(position.x, -470, 470)
	position.y = clamp(position.y, -355, 90)

func shoot():
	if polarFx:
		polarFx.shoot()

func pauseChanged():
	pass

func getAutoaimTarget() -> Node2D:
	var monsters : Array = autoAimArea.get_overlapping_areas()
	if monsters.is_empty():
		return null
	var hittableMonsters := []
	for m in monsters:
		if m.canBeHit():
			hittableMonsters.append(m)
	hittableMonsters.sort_custom(Callable(self, "sortByDistance"))
	if hittableMonsters.is_empty():
		return null
	return hittableMonsters[0]


func getClosestOverlappingOrb() -> Node2D:
	var orbs = $OrbDetector.get_overlapping_areas()
	if orbs.is_empty():
		return null
	orbs.sort_custom(Callable(self, "sortByDistance"))
	return orbs[0].get_parent()


func sortByDistance(a, b):
	return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position)


func getShotPosition() -> Vector2:
	var target = getAutoaimTarget()
	if autoAimArea.visible and target:
		return target.getCenter()
	else:
		return global_position


func setPerfect(perfect:bool):
	isPerfect = perfect


func enablePerfectTiming():
	if polarFxPerfectRing:
		polarFxPerfectRing.show()


var isCharging := false
func charge(c:bool):
	isCharging = c


func setRemainingQuickshots(amount:int):
	polarFx.setRemainingQuickshots(amount)


@onready var effectInner = $EffectInner
@onready var arcFollowInner = $EffectInner/ArcGroupFollow
@onready var effectOuter = $EffectOuter
@onready var arcFollowOuter = $EffectOuter/ArcGroupFollow
var arcPosTime := 0.0
var arcPosTime2 := 0.0
var pTime := 0.0
func updateVisual(delta):
	if polarFx:
		polarFx.position = global_position
		var multi := 13.0 if isPerfect else 8.0
		var extra_scale := 1.25 if isPerfect else 1.0
		var scale_charge := remap(ease(shotCharge, 1.4), 0, 1, 1.8, 1.0)*extra_scale
		polarFx.scale = lerp(polarFx.scale, Vector2.ONE * scale_charge, delta*30)
		var power = 1.1 if not isCharging else 1.3
		#var chargePower:float = ease(clamp(shotCharge-0.9, 0.0, 1.0)*multi, 3.0) # old, remove when we finalized the new fx
		var chargePower:float = -ease(shotCharge, 8.0)*0.3
		polarFx.setPower(modulate.a*power + chargePower)
		if isPerfect:
			pTime = min(pTime+delta*30.0, 1.0)
		else:
			pTime = max(pTime-delta*60.0, 0.0)
		polarFx.setPerfectTiming(pTime)
		var easedShotCharge := ease(remap(clamp(shotCharge-0.9, 0.0, 0.1), 0.0, 0.1, 0.0, 1.0), 0.5)
		polarFxPerfectRing.modulate.a = ease(easedShotCharge, 2.3)
		polarFxPerfectRing.scale = Vector2.ONE * remap(easedShotCharge, 1.0, 0.0, 0.01, 1.5)
	
		if shotCharge >= 1.0 and not polarFxShotReady.visible:
			polarFx.setPower(modulate.a*power)
			polarFxShotReady.scale = Vector2.ZERO
			polarFxShotReady.show()
			if shotReadyScaleTween:
				shotReadyScaleTween.kill()
			shotReadyScaleTween = create_tween()
			shotReadyScaleTween.tween_property(polarFxShotReady, "scale", Vector2(2,2), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			
		elif shotCharge < 1.0 and polarFxShotReady.visible:
			polarFxShotReady.hide()
	
	var rotSpeed := remap(shotCharge, 0, 1, 6, 14)
	arcPosTime = wrapf(arcPosTime+delta*1.6, 0, TAU)
	arcPosTime2 = wrapf(arcPosTime2-delta*3.2, 0, TAU)
	effectInner.rotation = wrapf(effectInner.rotation+delta*rotSpeed, 0, TAU)
	effectOuter.rotation = wrapf(effectOuter.rotation-delta*rotSpeed*2, 0, TAU)
	
	var interval = remap(shotCharge, 0, 1, 12, 4)
	var ttl = remap(shotCharge, 0, 1, 0.8, 0.2)
	var dist = remap(shotCharge, 0, 1, 12, 4)
	
	arcFollowInner.modulate.a = (shotCharge*0.3)+0.8
	arcFollowInner.interval = interval
	arcFollowInner.arcTtlFactor = ttl
	arcFollowInner.position.x = dist+(sin(arcPosTime)+1)*2.0
	
	arcFollowOuter.modulate.a = (shotCharge*0.3)+0.8
	arcFollowOuter.interval = interval
	arcFollowOuter.arcTtlFactor = ttl
	arcFollowOuter.position.x = dist+(sin(arcPosTime2)+1)*2.0
	
