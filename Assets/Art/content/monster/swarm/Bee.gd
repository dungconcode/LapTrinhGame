extends "res://content/monster/Monster.gd"

var neighbors := []
var dir := Vector2()
var swarmCenter

var updateCooldown := 0.0
var animationSpeed := 1.0

func init():
	$Sprite2D.speed_scale = 1.2 - randf() * 0.2

func subProcess(delta):
	updateCooldown -= delta
	if updateCooldown <= 0.0:
		updateCooldown += 0.0 + randf() *0.1
		if neighbors.size() == 0:
			dir = - position * 100000
			return
		
		var toCenter = position - swarmCenter.position
		if toCenter.length() > 20.0:
			if toCenter.x > 10.0 and dir.x > 0:
				dir.x -= toCenter.x * 50 
			if toCenter.x < -10.0 and dir.x < 0:
				dir.x -= toCenter.x * 50 
			if toCenter.y > 10.0 and dir.y > 0:
				dir.y -= toCenter.y * 50 
			if toCenter.y < -10.0 and dir.y < 0:
				dir.y -= toCenter.y * 50 
			
		dir *= 0.9
		dir.x += randf_range(-10000, 10000)
		dir.y += randf_range(-10000, 10000)
		var toward := Vector2()
		for n in neighbors:
			var dist = n.global_position - global_position
			var e := 0.0
			if dist.length() < 10:
				e = -pow((dist.length() - 10), 4)*2
				dir += dist * e
			else:
				e = pow((dist.length() - 10), 2)
				toward += dist * e
		
		if neighbors.size() < 5:
			dir += toward / float(neighbors.size())
		
		dir = dir.limit_length(50000)
		$Sprite2D.speed_scale = 0.5 + min(2.0, dir.length() / 25000.0)
		if abs(dir.x) > 5000:
			$Sprite2D.flip_h = dir.x > 0.0
	position += dir * delta * 0.002

func leave(delta:float):
	position.y -= delta * 50
	position.x += delta * position.x * 0.1 

func onGameLost():
	leaving = true

func handleDamage():
	$Sprite2D.play("hit")

func resumeAfterStagger():
	pass

func _on_Neighborhood_area_entered(area: Area2D) -> void:
	neighbors.append(area)

func _on_Neighborhood_area_exited(area: Area2D) -> void:
	neighbors.erase(area)
