extends Path2D

@export var axisModulation: Vector2 = Vector2(0.5, 0)

func _ready():
	visible = true

func createPathProbe(actor) -> PathFollow2D:
	var pathProbe = Data.PATH_PROBE.instantiate()
	add_child(pathProbe)
	pathProbe.progress_ratio = 0.5
	pathProbe.axisModulation = axisModulation
	pathProbe.rotationCenter = getRotationCenter()
	pathProbe.actor = actor
	return pathProbe

func getRotationCenter() -> Vector2:
	return get_node("RotationCenter").position
