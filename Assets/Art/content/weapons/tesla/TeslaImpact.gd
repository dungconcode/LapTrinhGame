extends Node2D

@onready var impact_forks = $Modulated/ImpactForks
@onready var radius_indicator = $Modulated/RadiusIndicator


var sparksAmount := [120, 150, 210, 260, 310]
var sparkScales := [0.85, 1.0, 1.1, 1.15, 1.2]
var dustAmount := [10, 20, 30, 40, 50]
var scaleMods := [0.12, 0.2, 0.25, 0.3, 0.4]
var staticScales := [0.75, 1.0, 1.15, 1.3, 1.45]
var staticAmount := [3, 5, 7, 9, 12]
var impactCircleScale := [0.6, 0.8, 1.0, 1.15, 1.3]
var impactScale : float = impactCircleScale[0]
var indicatorScale : float = 0.0

func setPower(p:int):
	$Sparks.amount = sparksAmount[p]
	$Sparks.scale = Vector2.ONE*sparkScales[p]
	scaleMod = scaleMods[p]
	impactScale = impactCircleScale[p]
	$Modulated/Static.scale = Vector2.ONE*staticScales[p]
	$Modulated/Static2.scale = Vector2.ONE*staticScales[p]
	$Modulated/Static.amount = staticAmount[p]
	$Modulated/Static.amount = round(float(staticAmount[p])*2.2)
	indicatorScale = Data.of("tesla.radius") * 0.02

var rotTimer := 0.0
var scaleMod := 0.2
func _process(delta):
	rotTimer += delta
	if rotTimer > 0.04:
		rotTimer -= 0.04
		impact_forks.rotation = randf()
		impact_forks.flip_h = randi()%2 == 0
		impact_forks.flip_v = randi()%2 == 0
		impact_forks.scale = Vector2.ONE*(scaleMod+randf_range(-0.1, 0.1))
		radius_indicator.self_modulate.a = randf_range(0.8, 1.0)
	radius_indicator.scale = indicatorScale*Vector2.ONE*randf_range(0.80, 1.15)
	indicatorScale = clamp(indicatorScale-delta*0.2, 0.1, 5.0)


func _ready():
	Style.init(self)
	$Sparks.restart()
	$Tween.interpolate_property($Modulated/RadiusIndicator, "modulate", Color(2,2,2,1), Color(1,1,1,0), 0.7, Tween.TRANS_SINE, Tween.EASE_OUT, 0.15)
	$Tween.interpolate_property($Modulated/ImpactForks.material, "shader_parameter/progress", 1.0, -1.0, 0.7, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "scaleMod", 0.2, 0.4, 0.9, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_property($TeslaImpactCircle, "modulate:a", 1.0, 0.0, 0.16, Tween.TRANS_QUINT, Tween.EASE_OUT)
	$Tween.interpolate_property($Modulated/Static, "scale", Vector2.ONE*1.4, Vector2.ONE*0.3, 1.2, Tween.TRANS_SINE, Tween.EASE_IN, 0.3)
	$Tween.interpolate_property($Modulated/Static2, "scale", Vector2.ONE*1.4, Vector2.ONE*0.3, 1.2, Tween.TRANS_SINE, Tween.EASE_IN, 0.3)
	$Tween.interpolate_property($TeslaImpactCircle, "scale", Vector2.ONE*0.02, Vector2.ONE*impactScale, 0.16, Tween.TRANS_QUINT, Tween.EASE_OUT)
	$Tween.start()


func _on_Timer_timeout():
	$Modulated/Static.emitting = false
	$Modulated/Static2.emitting = false


func _on_FreeTimer_timeout():
	queue_free()
