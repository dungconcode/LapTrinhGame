extends Node2D

func _ready():
	$Line2D.add_point(Vector2.ZERO)
	$Line2D.add_point(Vector2.ZERO)
	$Line2D.modulate = Color(1,1,1,0)

func start(direction):
	show()
	$ShootRay.rotation = direction.angle()
	$ShootRay.force_raycast_update()
	if $ShootRay.is_colliding():
		var pt = $ShootRay.get_collision_point()
		
		$Sparks.restart()
		$Sparks.global_position = pt
		$Line2D.points[1] = to_local(pt)
		$Sparks.rotation = (pt - global_position).angle()
		$Sparks.emitting = true
		
		$Line2D.modulate = Color(1,1,1,1)
		var t = create_tween()
		t.tween_property($Line2D, "modulate", Color(1,1,1,0), 0.02)
		
	$Flash.show()
	$Flash.position = Vector2(10, 0).rotated(direction.angle())
	$Flash.rotation = direction.angle()
	$Flash.frame = 0
	$Flash.play("flash")
