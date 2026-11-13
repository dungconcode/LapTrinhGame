extends Area2D

const whistleVol := [-12.0, -6.0, -2.0, 3.0, 7.0]
const whistlePitch := [1.6, 1.3, 1.15, 1.0, 0.8]

var velocity:Vector2
var exploded := false
var aliveTime := 0.0
var fuseStarted := false
var fullEffect := true
var directlyHitBody
@onready var last_point := global_position
@onready var bulletSmoke : Node2D = null

func _ready():
	var cannonBarrelSize : int = int(Data.of("artillery.cannonbarrelsize"))
	var smokeSize = 6.0
	match cannonBarrelSize:
		5:
			$Sprite2D.frame = 2
		_:
			$Sprite2D.frame = cannonBarrelSize
	smokeSize += ($Sprite2D.frame * 1.8)
	Style.init(self)
	bulletSmoke = preload("res://content/weapons/artillery/BulletSmoke.tscn").instantiate()
	Level.map.addPixelEffect(bulletSmoke)
	bulletSmoke.material = preload("res://content/weapons/artillery/MortarSmokeMat.tres")
	bulletSmoke.position = Vector2.ZERO
	bulletSmoke.width = smokeSize
	bulletSmoke.points[0] = global_position
	bulletSmoke.points[1] = global_position
	bulletSmoke.modulate.r = randf()
	bulletSmoke.modulate.g = randf()
	self.connect("tree_exiting", Callable(bulletSmoke, "queue_free").bind(), CONNECT_ONE_SHOT)
	Style.init(bulletSmoke)
	$Tween.interpolate_property(bulletSmoke, "modulate:b", 1, 0, 0.05, Tween.TRANS_SINE, Tween.EASE_IN)
	$Tween.interpolate_property(bulletSmoke, "modulate:b", 0, 1, 2.5, Tween.TRANS_SINE, Tween.EASE_IN, 1.5)
	$Tween.start()

func fire(initialVelocity):
	velocity = Vector2(0,-initialVelocity).rotated(rotation)
	$Explosion.visible = false
	var radius = Data.of("artillery.grenadesexplosionradius")
	$ExplosionArea/CollisionShape2D.shape.radius = radius
	$Explosion.scale = Vector2.ONE * (radius / 9.0)
	rotation = velocity.angle()
	var flash = preload("res://content/weapons/artillery/Muzzleflash.tscn").instantiate()
	flash.scale = Vector2.ONE * (2.3 + remap($Sprite2D.frame, 0, 4, 0.0, 1.5))
	flash.rotation = rotation
	flash.position = position
	Level.map.addPixelEffect(flash)

func down():
	var whistle = $WhistlePlain
	if Data.of("artillery.direct"):
		whistle = $WhistleDirect
	elif  Data.of("artillery.splash"):
		whistle = $WhistleSplash
	whistle.volume_db = whistleVol[$Sprite2D.frame]
	whistle.pitch_scale = whistlePitch[$Sprite2D.frame]
	whistle.play()

func _physics_process(delta):
	if GameWorld.paused or exploded:
		return
	var lastYVel = velocity.y
	velocity.y += delta * Data.of("artillery.grenadeGravity")
	if fullEffect and sign(velocity.y) != sign(lastYVel):
		down()
	
	position += delta * velocity
	rotation = velocity.angle()
	
	if last_point.distance_to(global_position) > 5.0:
		last_point = global_position
		bulletSmoke.add_point(global_position)
	else:
		bulletSmoke.points[-1] = global_position
	if bulletSmoke.get_point_count() > 100:
		bulletSmoke.remove_point(0)
	
	aliveTime += delta
	if aliveTime > 10.0:
		queue_free()

func _on_FuseTimer_timeout():
	explode()

func _on_Grenade_area_entered(area):
	if fuseStarted or exploded:
		return
	
	if area.is_in_group("monster") and not fuseStarted:
		fuseStarted = true
		directlyHitBody = area
		$FuseTimer.start()
	else:
		explode()


func explode():
	if exploded:
		return
	exploded = true
	$Whistle.stop()
	# Fade out Trail
	$Tween.remove_all()
	$Tween.interpolate_property(bulletSmoke, "modulate:b", bulletSmoke.modulate.b, 1, 0.8, Tween.TRANS_SINE, Tween.EASE_IN)
	# Add Explosion Effect
	var explosion = preload("res://content/weapons/artillery/MortarExplosion.tscn").instantiate()
	var explosionScaleFactor = remap(Data.of("artillery.grenadesexplosionradius"), 40, 160, 0.8, 1.4)
	explosion.size = $Sprite2D.frame
	explosion.scale = Vector2.ONE * explosionScaleFactor
	explosion.rotation = rotation+PI+randf_range(-0.15, 0.15)
	explosion.position = $CollisionShape2D.global_position
	explosion.radius = Data.of("artillery.grenadesexplosionradius")
	explosion.splashMode = Data.of("artillery.splash")
	Level.map.addPixelEffect(explosion)
	# Add Debris
	if global_position.y > -40:
		var Smoke = preload("res://content/weapons/artillery/SmoketrailDebris.tscn")
		for i in int(round(((($Sprite2D.frame+1)*2)+randi()%($Sprite2D.frame+1)))):
			var s = Smoke.instantiate()
			s.speed = explosionScaleFactor
			s.position = $CollisionShape2D.global_position
			Level.map.call_deferred("add_child", s)
	
	var sound = null
	if Data.of("artillery.soundlevel") == 0:
		sound = $ImpactPlain
	else:
		if Data.of("artillery.direct"):
			match int(Data.of("artillery.soundlevel")):
				1:
					sound = $ImpactDirect
				2:
					sound = $ImpactDirect2
				3:
					sound = $ImpactDirect3
				4:
					sound = $ImpactDirect4
		elif Data.of("artillery.splash"):
			match int(Data.of("artillery.soundlevel")):
				1:
					sound = $ImpactSplash
				2:
					sound = $ImpactSplash2
				3:
					sound = $ImpactSplash3
				4:
					sound = $ImpactSplash4
	if not fullEffect:
		sound.setAdditionalVolume(-4.0)
	sound.play()
	$Sprite2D.visible = false
	var dmg = Data.of("artillery.grenadedamage")
	for n in $ExplosionArea.get_overlapping_areas():
		if n.is_in_group("monster"):
			if directlyHitBody == n:
				if Data.of("artillery.direct"):
					# Martin: If you want to add a special sound for a direct hit with the direct hit upgrade, here's the spot
					var directHitEffect = load("res://content/weapons/artillery/ArtilleryDirectHit.tscn").instantiate()
					directHitEffect.scale = Vector2.ONE * remap($Sprite2D.frame, 1, 4, 0.5, 1.0)
					$DirectHitSound.play()
					directHitEffect.position = $CollisionShape2D.global_position
					directHitEffect.rotation = rotation
					Level.map.addPixelEffect(directHitEffect)
				var extra = Data.of("artillery.directhitdamage")
				n.hit("artillery", dmg * extra, dmg * 0.05 * extra)
			else:
				n.hit("artillery",dmg, dmg * 0.05)
	$Tween.interpolate_callback(self, 0.1, "set", "visible", false)
	$Tween.interpolate_callback(self, 2.5, "queue_free")
	$Tween.start()

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()
