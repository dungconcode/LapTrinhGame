extends Line2D

var ttlFactor := 1.0
var alphaMod := 1.0
var darkColorMod := 0.1
var darkColor := Color.RED
var lightColor := Color.BLUE
var fork := false

@onready var pCount := get_point_count()

func _ready():
	modulate = lightColor
	modulate.a *= alphaMod
	darkColor.a = alphaMod*darkColorMod
	lightColor.a *= alphaMod
	$Start.scale = Vector2.ONE*randf_range(0.7, 1.3)
	$End.scale = Vector2.ONE*randf_range(0.7, 1.3)
	material.set_shader_parameter("length_factor", points[-1].x/300)
	var tween := create_tween()
	tween.set_parallel().tween_callback(set_modulate.bind(darkColor)).set_delay(0.05*ttlFactor)
	tween.tween_callback(set_modulate.bind(lightColor)).set_delay(0.1*ttlFactor)
	tween.tween_property(self, "modulate:a", 0, 1.6*ttlFactor).from(0.5*alphaMod).set_delay(0.1*ttlFactor).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Start, "modulate:a", 0, 0.6*ttlFactor).from(alphaMod).set_delay(0.1*ttlFactor).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property($End, "modulate:a", 0, 0.6*ttlFactor).from(alphaMod).set_delay(0.1*ttlFactor).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(material, "shader_parameter/disappear", 0.0, 1.2*ttlFactor).from(1.0).set_delay(0.1*ttlFactor).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_callback(queue_free).set_delay(1.7*ttlFactor)
	$End.position = points[-1]
	if fork:
		width = round(randf_range(5,8))
		gradient = preload("res://content/weapons/tesla/arc/ArcGradientFork.tres")
		width_curve = preload("res://content/weapons/tesla/arc/ArcWidthFork.tres")
		$End.hide()


var time := 0.0
func _process(delta):
	time += delta
	if time > 0.4:
		set_process(false)
	for i in pCount:
		if i == 0 or i == pCount-1:
			continue
		points[i] += Vector2(randf_range(-30, 30), sign(points[i].y)*30.0+randf_range(-10, 10))*delta
