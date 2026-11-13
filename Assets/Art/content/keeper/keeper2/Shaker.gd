extends RigidBody2D

var lifeTime:float

var baseDamage:float
var damageDealt := 0.0

var affectedTile
var hitCooldown:float = 0.0

func _ready():
	lifeTime = 6.0

func _physics_process(delta):
	if GameWorld.paused:
		return
	
	if affectedTile:
		if hitCooldown > 0.0:
			hitCooldown -= delta
		else:
			var dir = global_position - affectedTile.global_position
			affectedTile.hit(dir, 1)
			hitCooldown = 1.0
		return
	
	lifeTime -= delta
	
	if lifeTime <= 0.0:
		queue_free()

func _on_Shaker_body_entered(body):
	if not body.has_meta("destructable") or not body.get_meta("destructable"):
		return
	
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	set_freeze_enabled.call_deferred(true)
	affectedTile = body
	affectedTile.connect("destroyed", Callable(self, "tileDestroyed"))
	modulate *= 3.0

func tileDestroyed():
	affectedTile = null
	queue_free()
