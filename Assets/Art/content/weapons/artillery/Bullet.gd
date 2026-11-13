extends Area2D

var velocity:Vector2
var guides
var isActive := true
var isHoming := false
var bulletFading := false
var bulletBeingDestroyed := false
var trailLength := 10

@onready var last_point := global_position
@onready var bulletSmoke : Node2D = null
@onready var rocketEngine = $RocketEngine


func _ready():
	bulletSmoke = preload("res://content/weapons/artillery/BulletSmoke.tscn").instantiate()
	if Data.of("artillery.machinegunhoming"):
		bulletSmoke.material = preload("res://content/weapons/artillery/MortarSmokeMat.tres")
	else:
		bulletSmoke.material = bulletSmoke.material.duplicate()
	Level.map.addPixelEffect(bulletSmoke)
	bulletSmoke.position = Vector2.ZERO
	bulletSmoke.points[0] = global_position
	bulletSmoke.points[1] = global_position
	bulletSmoke.modulate.r = randf()
	bulletSmoke.modulate.g = randf()
	self.connect("tree_exiting", Callable(bulletSmoke, "queue_free").bind(), CONNECT_ONE_SHOT)
	Style.init(self)
	$Tween.interpolate_property(bulletSmoke, "modulate:b", 1, 0, 0.05, Tween.TRANS_SINE, Tween.EASE_IN)
	$Tween.interpolate_property(bulletSmoke, "modulate:b", 0, 1, 3.5, Tween.TRANS_SINE, Tween.EASE_IN, 0.5)
	$Tween.start()

func fire(initialVelocity:float):
	velocity = Vector2(0,-initialVelocity).rotated(rotation)
	rotation = velocity.angle()
	var flash = preload("res://content/weapons/artillery/Muzzleflash.tscn").instantiate()
	flash.rotation = rotation
	flash.position = position
	Level.map.addPixelEffect(flash)
	if Data.of("artillery.machinegunhoming"):
		isHoming = true
		rocketEngine.show()
		$Sparks.show()
		guides = preload("res://content/weapons/artillery/RayCastGuide.tscn").instantiate()
		add_child(guides)
		trailLength = 20
		$Sprite2D.texture = preload("res://content/weapons/artillery/projectile2.png")

func _physics_process(delta):
	if GameWorld.paused:
		return
	
	if isHoming:
		velocity = velocity.rotated(randf_range(-0.04, 0.04))
		rocketEngine.rotation_degrees = -90 + randf_range(-6, 6)
		rocketEngine.scale = Vector2(0.27, 0.33) * randf_range(0.75, 1.55)
	
	var speedMod := 1.0
	if guides and isActive:
		var dir = guides.guide()
		if dir != 0.0:
			speedMod = 2.0
		velocity = lerp(velocity, velocity.rotated(dir), delta * 20.0)
	position += delta * velocity * speedMod
	rotation = velocity.angle()
	if last_point.distance_to(global_position) > 15.0:
		last_point = global_position
		bulletSmoke.add_point(global_position)
	else:
		bulletSmoke.points[-1] = global_position
	if bulletSmoke.get_point_count() > trailLength:
		bulletSmoke.remove_point(0)
	
	if not bulletBeingDestroyed and position.length() > 1500:
		bulletBeingDestroyed = true
		queue_free()

func _on_Bullet_area_entered(area):
	if not isActive:
		return
	
	if area.is_in_group("monster"):
		if not isHoming:
			var dmg = Data.of("artillery.machinegundamage")
			area.hit("artillerymachinegun1", dmg, dmg * 0.16)
			if Data.of("artillery.machinegunbarrels") > 1:
				$Impact.setAdditionalVolume(-6.0)
			$Impact.play()
		else:
			# Martin: This sound is the Impact sound of the explosive projectile (for the Homing Rockets).
			# You can replace the sound or fine tune it.
			$ImpactExplosive.play()
		remove_bullet()
	else:
		if Data.of("artillery.machinegunbarrels") > 1:
			$Impact.setAdditionalVolume(-6.0)
		$Impact.play()
		remove_bullet()

func remove_bullet():
	var bullet = null
	if isHoming:
		bullet = preload("res://content/weapons/artillery/BulletImpactExplosive.tscn").instantiate()
		bullet.damage = Data.of("artillery.machinegundamage")
	else:
		bullet = preload("res://content/weapons/artillery/BulletImpact.tscn").instantiate()
	bullet.position = global_position + Vector2(randf_range(-2, 2), 0.0).rotated(rotation)
	bullet.rotation = rotation
	if isHoming:
		Level.map.call_deferred("add_child", bullet)
	else:
		Level.map.addPixelEffect(bullet)
	$Tween.remove_all()
	$Tween.interpolate_property(bulletSmoke, "modulate:b", bulletSmoke.modulate.b, 1, 0.9, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	$Sprite2D.hide()
	$RocketEngine.hide()
	$Sparks.emitting = false
	set_physics_process(false)
	isActive = false
	set_deferred("monitoring", false)

func _on_Impact_finished():
	queue_free()

func _on_ImpactExplosive_finished():
	queue_free()
