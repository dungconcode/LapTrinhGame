extends Area2D

@export var reflectable := true
@export var rotation_offset := 1.75

var damageSource:String
var spawnOnFree

var origin:Vector2
var target:Node2D
var target_position := Vector2.ZERO
var targeting_speed := 0.0
var damage:int
var speed:float
var lifetime := 0.0
var flying := true
var velocity := Vector2(-0.1, 1.0).normalized()

@onready var sprite = $Sprite2D
@onready var trail = $Trail

func _ready():
	sprite.play("flying")
	Style.init(self)
	if target:
		target_position = target.position
	else:
		queue_free()

func setAnimationSuffix(animationSuffix):
	self.animationSuffix = animationSuffix

func _physics_process(delta):
	if not flying or GameWorld.paused:
		return
	
	lifetime = min(lifetime+delta, 3.0)
	if target and is_instance_valid(target) and not target.dead:
		target_position = target.position
	else:
		sprite.hide()
		deactivate()
		target = null
		return
	var d = target_position - position
	var d_len:float = d.length()
	position += (velocity * delta * speed).limit_length(d_len)
	targeting_speed = min(targeting_speed+delta*60.0, 20.0)
	velocity = lerp(velocity, d.normalized(), delta*targeting_speed).normalized()
	rotation = velocity.angle()
	
	var rate:float= remap(lifetime, 0.0, 3.0, 1.0, 0.2)
	sprite.scale = Vector2.ONE * rate
	trail.amount_ratio = rate
	
	if lifetime >= 3.0:
		sprite.hide()
		deactivate()
		return


func spawnExplosionIfAppropriate():
	if spawnOnFree:
		spawnOnFree.rotation = rotation + PI*0.75
		spawnOnFree.position = position
		get_parent().call_deferred("add_child", spawnOnFree)
		spawnOnFree = null

func setToDamageMonsters():
	set_collision_layer_value(CONST.LAYER_MONSTER_PROJECTILES, false)
	set_collision_mask_value(CONST.LAYER_WEAPONS, true)
	remove_from_group("projectile")

func _on_Projectile_area_entered(area: Area2D) -> void:
	# only check if set as a weapon
	if flying and area.is_in_group("monster"):
		area.hit(damageSource, damage, 1.0)
		sprite.scale = Vector2.ONE
		$ImpactSound.play()
		sprite.play("hit")
		spawnExplosionIfAppropriate()
		deactivate()


func deactivate():
	if not flying:
		return
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	for c in get_children():
		if c is CollisionShape2D:
			c.set_deferred("disabled", true)
	flying = false
	$Trail.emitting = false
	$FreeTimer.start()


func _on_free_timer_timeout():
	queue_free()
