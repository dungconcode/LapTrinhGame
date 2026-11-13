extends Node2D

var origin:Vector2
var goalPos:Vector2
var velocity := Vector2()
var speed := 450
var acceleration := 6.0
var buff:float
var returning := false
var curve:Curve2D
var curveOffset:float
var cooldown := 1.0
var targetReached:bool
var target

func _ready():
	origin = position
	$Sprite.play("idle")
	
	Style.init(self)

func returToOrigin():
	goalPos = origin
	returning = true
	target = null

func setCurve(curve:Curve2D):
	self.curve = curve
	curveOffset = randf_range(0, curve.get_baked_length())
	goalPos = curve.sample_baked(curveOffset)

func assignTarget(target):
	self.target = target
	$Sprite.play("quick")

func targetDied():
	if targetReached:
		queue_free()
	else:
		target = null
		$Sprite.play("idle")

func _physics_process(delta):
	if GameWorld.paused or not curve:
		return
	
	if target:
		if targetReached:
			position = target.getCenter()
			var stunLevel = (1.0 + buff) * Data.of("droneyard.battledronestrength") * target.fullStunAt
			target.hit("droneyardparasites", 0, stunLevel, true)
			return
		else:
			goalPos = target.position + (target.position - position) * 10
	
	var direction = (goalPos - position).limit_length(speed)
	velocity = lerp(velocity, direction, delta * acceleration)
	position += velocity * delta
	
	if cooldown > 0.0:
		cooldown -= delta
		return
	
	if returning:
		if direction.length() < 3.0:
			queue_free()
	elif target and (target.position - position).length() < 5.0:
		targetReached = true
		target.damageModifier *= 1.0 + Data.of("droneyard.battledronestrength") * (1.0 + buff)
		$Sprite.speed_scale = 0.2
		$Sprite.play("quick")
		rotation = randf_range(-0.5, 0.5)
		$AttachDroneSound.play()
	else:
		curveOffset += delta * speed * 0.5 * randf_range(0.4, 2.0)
		curveOffset = fmod(curveOffset, curve.get_baked_length())
		goalPos = curve.sample_baked(curveOffset)

func canTakeTarget() -> bool:
	return not returning and cooldown <= 0.0 and not target
