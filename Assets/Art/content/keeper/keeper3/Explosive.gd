extends RigidBody2D

var countdown := 1.5
var exploded = false
var lastVelocity:Vector2

func _physics_process(delta: float) -> void:
	if not exploded:
		countdown -= delta
		if countdown <= 0.0:
			explode(lastVelocity)
		elif linear_velocity.length() < lastVelocity.length() * 0.8 and lastVelocity.length() > 2.0:
			explode(lastVelocity)
	lastVelocity = linear_velocity

func _on_body_entered(body: Node) -> void:
	if not body.has_meta("destructable") or not body.get_meta("destructable"):
		return
	
	#explode(lastVelocity.normalized())

func explode(direction := Vector2.ZERO):
	if exploded:
		return
	
	var ex = load("res://content/gadgets/blastMining/Explosion.tscn").instantiate()
	ex.position = position
	ex.shake_strength = 100
	get_parent().add_child(ex)
	var radius = 1.5
	var offset = lastVelocity.normalized() * radius * 0.8 * GameWorld.TILE_SIZE
	Level.map.damageTileCircleArea(global_position, radius, 20, 0.1, offset)
	exploded = true
	queue_free()
