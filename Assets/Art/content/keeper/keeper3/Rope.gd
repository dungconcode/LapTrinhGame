extends Line2D

signal on_connected

var origin_point:Vector2
var connect_point:Vector2
var direction:Vector2

var growing := false
var shrinking := false
var connected := false

func start(direction:Vector2):
	self.direction = direction
	$ConnectRay.rotation = direction.angle()
	growing = true
	add_point(Vector2())
	add_point(Vector2(direction * 10))


func stop():
	growing = false
	shrinking = true

func _physics_process(delta: float) -> void:
	if growing:
		points[1] += direction * delta * 500
		$ConnectRay.position = points[1]
		var coll = $ConnectRay.get_collider()
		if coll:
			connected = true
			growing = false
			connect_point = $ConnectRay.get_collision_point()
			points[1] = connect_point - position
			default_color = Color.CORAL
			width = 1.5
			on_connected.emit()
	elif shrinking:
		points[0] = lerp(points[0], points[1], delta * 10)
		if points[0].distance_to(points[1]) < 10:
			queue_free()

func update_origin(pos):
	points[0] = pos - position

func get_angle() -> float:
	return -(CONST.PI_HALF + (points[1] - points[0]).angle())
