extends Area2D

@export var reflectable := true
@export var rotation_offset := 1.75

var damageSource:String
var spawnOnFree

var path:Curve2D
var damage:int
var speed:float
var flying := false
var pathProgress:float
var tween:DeprecatedTween
var direction:Vector2

func _ready():
	$Sprite2D.play("flying")
	Style.init(self)
	tween = DeprecatedTween.new()
	add_child(tween)
	add_to_group("pauseL")
	
	speed *= Data.of("monstermodifiers.projectilespeed")

func start(path, interpolation:int, easing:int):
	self.path = path
	var pathLength = path.get_baked_length()
	var time = pathLength / speed
	position = path.sample_baked(pathProgress)
	tween.interpolate_property(self, "pathProgress", 0, pathLength, time, interpolation, easing)
	tween.interpolate_callback(self, time, "onTravelFinished")
	tween.start()
	flying = true

func _physics_process(delta):
	if not flying or GameWorld.paused:
		return
	
	position = path.sample_baked(pathProgress)
	direction = path.sample_baked(pathProgress + 5.0) - position
	rotation = direction.angle() + rotation_offset #5.55

func onTravelFinished():
	if get_collision_layer_value(CONST.LAYER_MONSTER_PROJECTILES):
		Level.dome.requestProjectileDamage(damage, global_position, self)
		InputSystem.shake(min(100, damage), 0.2, 10, global_position)
	else:
		flying = false
		queue_free()

func domeAcceptsDamage():
	$ImpactSound.play()
	spawnExplosionIfAppropriate()
	deactivate()

func _on_sprite_2d_animation_looped() -> void:
	_SpriteAnimationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_SpriteAnimationFinishedCheck()

func _SpriteAnimationFinishedCheck() -> void:
	if $Sprite2D.animation == "hit":
		queue_free()

func spawnExplosionIfAppropriate():
	if spawnOnFree:
		spawnOnFree.rotation = rotation + PI*0.75
		spawnOnFree.position = position
		get_parent().call_deferred("add_child", spawnOnFree)
		spawnOnFree = null

func domeAbsorbsDamage():
	if flying:
		$ShieldedSound.play()
		deactivate()

func domeReflectsDamage(returnedDamage := 0.0, returnedSpeed := 1.0, damageModifier := 1.0, duration := 0.0):
	$ShieldedSound.play()
	
	if returnedDamage > 0.0:
		deactivate()
		return
	
	speed *= returnedSpeed
	damage *= damageModifier
	
	path.clear_points()
	path.add_point(position)
	path.add_point(position - direction * 1000)
	var pathLength = path.get_baked_length()
	var time = pathLength / speed
	pathProgress = 0
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(self, "pathProgress", 0, pathLength, time, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_callback(self, time, "deactivate")
	tween.start()
	
	# switch from Projectile to Weapon
	setToDamageMonsters()

func setToDamageMonsters():
	set_collision_layer_value(CONST.LAYER_MONSTER_PROJECTILES, false)
	set_collision_mask_value(CONST.LAYER_WEAPONS, true)
	remove_from_group("projectile")

func _on_Projectile_area_entered(area: Area2D) -> void:
	if flying and area.is_in_group("monster"):
		area.hit(damageSource, damage, 1.0)
		spawnExplosionIfAppropriate()
		$ImpactSound.play()
		deactivate()

func deactivate():    
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	for c in get_children():
		if c is CollisionShape2D:
			c.set_deferred("disabled", true)
	tween.stop_all()
	tween.remove_all()
	flying = false
	$Sprite2D.play("hit")

func pauseChanged():
	if GameWorld.paused:
		tween.stop_all()
	else:
		tween.resume_all()
