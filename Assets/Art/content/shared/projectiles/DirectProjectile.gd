extends Area2D

@export var reflectable := true
@export var rotation_offset := 1.75

var damageSource:String
var spawnOnFree

var origin:Vector2
var target:Vector2
var damage:int
var speed:float
var flying := true

var animationSuffix:String = ""

func _ready():
	var animatedSprite: AnimatedSprite2D = $Sprite2D as AnimatedSprite2D
	animatedSprite.animation_looped.connect(_on_sprite2D_animation_looped)
	if $Sprite2D.sprite_frames.has_animation("start" + animationSuffix):
		$Sprite2D.play("start" + animationSuffix)
	else:
		$Sprite2D.play("flying" + animationSuffix)
	
	speed *= Data.of("monstermodifiers.projectilespeed")
	
	Style.init(self)

func setAnimationSuffix(animationSuffix):
	self.animationSuffix = animationSuffix

func _physics_process(delta):
	if not flying or GameWorld.paused:
		return
	
	var d = target - position
	rotation = d.angle() + PI * rotation_offset
	position += (d.normalized() * delta * speed).limit_length(d.length())
	
	if d.length() < 2.0:
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

func _on_sprite2D_animation_looped() -> void:
	_sprite2DAnimationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_sprite2DAnimationFinishedCheck()

func _sprite2DAnimationFinishedCheck() -> void:
	if $Sprite2D.animation == "hit" + animationSuffix:
		queue_free()
	elif $Sprite2D.animation == "start" + animationSuffix:
		$Sprite2D.play("flying" + animationSuffix)

func spawnExplosionIfAppropriate():
	if spawnOnFree:
		spawnOnFree.rotation = rotation + PI*0.75
		spawnOnFree.position = position
		get_parent().call_deferred("add_child", spawnOnFree)
		spawnOnFree = null

func domeAbsorbsDamage():
	domeAcceptsDamage()

func domeReflectsDamage(returnedDamage := 0.0, returnedSpeed := 1.0, damageModifier := 1.0, duration := 0.0):
	$ShieldedSound.play()
	
	if returnedDamage > 0.0:
		deactivate()
		return
	
	speed *= returnedSpeed
	damage *= damageModifier
	target = origin + (origin - position)
	# switch from Projectile to Weapon
	setToDamageMonsters()
	
func setToDamageMonsters():
	set_collision_layer_value(CONST.LAYER_MONSTER_PROJECTILES, false)
	set_collision_mask_value(CONST.LAYER_WEAPONS, true)
	remove_from_group("projectile")

func _on_Projectile_area_entered(area: Area2D) -> void:
	# only check if set as a weapon
	if flying and area.is_in_group("monster"):
		area.hit(damageSource, damage, 1.0)
		$ImpactSound.play()
		spawnExplosionIfAppropriate()
		deactivate()

func deactivate():
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	for c in get_children():
		if c is CollisionShape2D:
			c.set_deferred("disabled", true)
	flying = false
	$Sprite2D.play("hit" + animationSuffix)
