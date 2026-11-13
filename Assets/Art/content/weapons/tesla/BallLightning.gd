extends Area2D

var strength:float
var baseDamage:float
var wasStrengthened:bool

var timeSinceLastHit:float = 99.0

func _physics_process(delta):
	if GameWorld.paused:
		return
	
	strength *= 1.0 - 0.05 * delta
	if not wasStrengthened:
		strength -= delta
	
	if strength <= 0.0:
		queue_free()
		return
	
	var radius = sqrt(strength / PI) * 20
	
	$CollisionShape2D.shape.radius = radius
	$Polygon2D.scale = Vector2.ONE * radius / 10.0
	
	timeSinceLastHit += delta
	
	var hitStrength = sqrt(strength) * baseDamage
#	prints(baseDamage, strength, hitStrength)
	for monster in get_overlapping_areas():
		if monster.canBeHit():
			monster.hit("teslaorbs", hitStrength * delta, 0.5 + hitStrength * 0.05)
			if not wasStrengthened:
				strength -= delta * 2
			timeSinceLastHit = 0.0
	
	if timeSinceLastHit < 0.5:
		$Hitting.startIfNotPlaying()
	else:
		$Hitting.stopIfPlaying()
	
	wasStrengthened = false

func strengthen(amount:float):
	strength += amount
	wasStrengthened = true
