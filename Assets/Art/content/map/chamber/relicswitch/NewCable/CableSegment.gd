extends Line2D

@onready var orig_points := points

var isShadow := false
var cableLength : float = 10.0
var cableTotalLength : float = 10.0
var cableOffset : float = 0.0
var time := 0.0
var activationPower := 0.0


func _ready():
	Style.init(self)
	set_process(false)
	cableLength = cableTotalLength * 0.03
	if not isShadow:
		modulate.r = remap(clamp(cableLength, 0.5, 1.5), 0.5, 1.5, 0.4, 1.0)
		if cableOffset > 0:
			modulate.b = cableOffset / 160.0
		else:
			modulate.b = 0.0
		modulate.g = cableTotalLength / 160.0
		$Entry.queue_free()
		$Exit.queue_free()
	else:
		$Entry.rotation = randf()*TAU
		$Entry.scale = Vector2.ONE*randf_range(0.4, 0.6)
		$Entry.position = points[0]
		
		$Exit.rotation = randf()*TAU
		$Exit.scale = Vector2.ONE*randf_range(0.4, 0.6)
		$Exit.position = points[-1]
		material = null
		modulate = Color(0,0,0,0.3)
		z_index = 9
		for i in orig_points.size():
			orig_points[i].y += cableTotalLength*0.3 * sin(remap(i, 0, (orig_points.size()-1)*2.0, 0, TAU))
		points = orig_points


func activate():
	if not isShadow:
		modulate.a = 0.1
	set_process(true)
	$Tween.interpolate_property(self, "activationPower", 0, 1, 1.0)
	$Tween.start()


func deactivate():
	if not isShadow:
		modulate.a = 1.0
	$Tween.interpolate_property(self, "activationPower", 1, 0, 1.0)
	$Tween.interpolate_callback(self, 1.0, "set_process", false)
	$Tween.start()


func _process(delta):
	time = wrapf(time+delta*1.2, 0, 1)
	for i in points.size():
		points[i].y = orig_points[i].y + (cableLength * sin(cableOffset+i-time*TAU) * sin(remap(i, 0, (points.size()-1)*2.0, 0, TAU)) * activationPower)
