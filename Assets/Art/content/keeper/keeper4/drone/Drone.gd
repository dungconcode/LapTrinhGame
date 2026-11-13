extends RigidBody2D

var target
var hitTiles := []
var hitCooldown := 0.0

func setTarget(node):
	target = node

func _physics_process(delta):
	var d = target.global_position - global_position
	var change = d.angle() - rotation
	if angular_velocity < -4.0 and change < 0:
		change = 0
	if angular_velocity > 4.0 and change > 0:
		change = 0
	
	if change > PI:
		change -= 2*PI
	elif change < -PI:
		change += 2*PI
	var turningRightAlready = sign(change) == sign(angular_velocity)
	if not turningRightAlready or turningRightAlready and abs(angular_velocity) < 3.0:
		apply_torque_impulse(change*2.0)
	
	var speedDiff = d.length() - linear_velocity.length() 
	var rotationOffsetDampening = (1.0 - min(abs(change), 1.0))*1.0
	var propulsionDirection = Vector2.RIGHT.rotated(rotation)
	var speedDampening = min(d.length()+12, 36) / 36.0
	if speedDiff < 0:
		Vector2.LEFT.rotated(rotation)
	apply_central_impulse(propulsionDirection * 3 * rotationOffsetDampening * speedDampening)
		
#		rotation += change * delta * 3.0
#		position += Vector2(1,0).rotated(rotation) * delta * 100
	
	if hitCooldown > 0.0:
		hitCooldown -= delta
	elif hitTiles.size() > 0:
		var body = hitTiles.front()
		var dir = global_position - body.global_position
		body.hit(dir, 0.5)
		apply_central_impulse(dir.normalized()*50)
		hitCooldown += 0.5


func _on_Area2D_body_entered(body):
	if body == target and body.has_meta("destructable") and body.get_meta("destructable"):
		hitTiles.append(body)

func _on_Area2D_body_exited(body):
	hitTiles.erase(body)
