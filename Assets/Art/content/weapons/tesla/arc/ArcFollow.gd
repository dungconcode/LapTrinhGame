extends Line2D


var randomizePointsOverLifetime := true
var ttlFactor := 1.0
var alphaMod := 1.0
var darkColorMod := 0.1
var darkColor := Color.RED
var lightColor := Color.BLUE
var fork := false
var originalPoints : PackedVector2Array = []

@onready var pCount := get_point_count()
@onready var tween := $Tween

func _ready():
	originalPoints = points
	modulate = lightColor
	modulate.a *= alphaMod
	darkColor.a = alphaMod*darkColorMod
	lightColor.a *= alphaMod
	material.set_shader_parameter("length_factor", points[-1].x/300)
	
	var tween := create_tween()
	tween.set_parallel().tween_callback(set_modulate.bind(darkColor)).set_delay(0.02*ttlFactor)
	tween.tween_callback(set_modulate.bind(lightColor)).set_delay(0.05*ttlFactor)
	tween.tween_property(self, "modulate:a", 0, 1.6*ttlFactor).from(0.5*alphaMod).set_delay(0.1*ttlFactor).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(material, "shader_parameter/disappear", 0.0, 1.2*ttlFactor).from(1.0).set_delay(0.1*ttlFactor).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_callback(queue_free).set_delay(1.7*ttlFactor)
	if fork:
		width = round(randf_range(5,8))
		gradient = preload("res://content/weapons/tesla/arc/ArcGradientFork.tres")
		width_curve = preload("res://content/weapons/tesla/arc/ArcWidthFork.tres")


var time := 0.0
var moved := false
func _process(delta):
	time += delta
	if time > 0.4*ttlFactor:
		set_process(false)
	
	points = originalPoints
	if int(round(time*12.0))%2 == 0:
		if moved:
			return
		moved = true
		for p in pCount:
			var move : Vector2 = Vector2.RIGHT.rotated(randf()*TAU)*randf()*delta
			points[p] += move*1500.0
			originalPoints[p] += move*250.0
	else:
		moved = false
	
	var dir = points[0].direction_to(points[-1])
	var p_dir = -sign((points[int(float(points.size())/2.0)]-points[0]).rotated(-dir.angle()).y)
	for i in pCount:
		originalPoints[i] += (dir.rotated(PI/2)+dir)*p_dir*delta*randf_range(-40, 60)*3.0
