extends Marker2D

var linear_velocity:Vector2

func _physics_process(delta):
	linear_velocity = get_parent().goalSpeed * get_parent().direction
