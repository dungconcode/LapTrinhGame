extends AnimatedSprite2D

var phase = 1
var dir = Vector2()
var speed = 0.0
var depth = 0.0
var can_explode = false
var done := false

func _ready():
	dir = Vector2(1, 0.3).rotated(randf_range(-0.1, 0.1)).normalized()
	rotation = dir.angle()
	depth = randf_range(0.5, 1.0)
	speed = randf_range(400, 600) * depth
	$GPUParticles2D.amount *= depth
	scale.x = depth
	scale.y = depth
	global_position.x = -960
	global_position.y = randf_range(-600, -200)
	can_explode = false
	# disable for now. The triggered explisions are "real" and can kill monsters, even if they happen invisibly in the back.
#	can_explode = randf() < 0.2
	play("default")

func _process(delta):
	if GameWorld.paused:
		return
	
	global_position += dir * speed * delta
	if can_explode and global_position.y >= get_parent().global_position.y and global_position.x < 480:
		can_explode = false
		var x = load("res://content/shared/explosions/Explosion99.tscn").instantiate()
		get_parent().add_child(x)
		x.global_position = global_position
		queue_free()
	
	if not $Tween.is_active() and (global_position.x > 480 or global_position.y > 0):
		$Tween.interpolate_callback(self, 2.0, "queue_free")
		$Tween.start()
