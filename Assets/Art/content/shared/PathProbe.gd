extends PathFollow2D

# little stretch on the x-axis
@export var axisModulation: Vector2

var rotationCenter:Vector2

var actor

func _physics_process(delta):
	var angle = (position - position * axisModulation - rotationCenter).angle() + PI*0.5
	if angle >= PI-0.01:
		# otherwise we get a flip on the left side
		angle -= 2*PI
	
	actor.rotation = clamp(angle, -1.0*PI, 1.0*PI)
	actor.position = position

func moveBy(move:float) -> float:
	var newOffset = clamp(progress_ratio + move, 0.0, 1.0)
	var thisMove = newOffset - progress_ratio
	progress_ratio = newOffset
	return thisMove

func getPathLengthModifier() -> float:
	return get_parent().curve.get_baked_length() / 200
