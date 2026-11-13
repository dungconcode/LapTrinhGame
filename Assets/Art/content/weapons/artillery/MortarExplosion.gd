extends Node2D

var size := 0
var radius := 10.0
var splashMode := false

func _ready():
	$RadiusScaler/Shockwave.material.set_shader_parameter("palette", Style.palette)
	Style.init(self)
	match size:
		0:
			$Particles.amount = 30
			$Sparks.amount = 25
			$ParticlesExtra.amount = 40
			InputSystem.shake(60, 3.0)
			$ExplosionSmall.frame = 0
		1:
			$Sparks.amount = 40
			$Particles.amount = 45
			$ParticlesExtra.amount = 60
			InputSystem.shake(100, 3.0)
			$ExplosionBig.frame = 0
			$ParticlesBig.restart()
		2:
			$Sparks.amount = 70
			InputSystem.shake(150, 3.0)
			$ExplosionBig.frame = 0
			$ParticlesBig.restart()
			$ExplosionSmallL.frame = 0
			$ExplosionSmallR.frame = 0
		3:
			$Sparks.amount = 90
			InputSystem.shake(150, 3.0)
			$ExplosionBig.frame = 0
			$ParticlesBig.restart()
			$ExplosionSmallL.frame = 0
			$ExplosionSmallR.frame = 0
		4:
			$Sparks.amount = 90
			InputSystem.shake(150, 3.0)
			scale *= 1.3
			$ExplosionBig.frame = 0
			$ParticlesBig.restart()
			$ExplosionSmallL.frame = 0
			$ExplosionSmallR.frame = 0
		_:
			pass
	if splashMode:
		$Sparks.amount *= 4.0
	$Particles.restart()
	$ParticlesExtra.restart()
	$RadiusScaler/Shockwave.rotation = randf()*TAU
	$RadiusScaler.global_scale = Vector2.ONE * (radius/10.0)
	$Tween.interpolate_callback($RadiusScaler/Circle, 0.05, "set_modulate", Color.WHITE)
	$Tween.interpolate_callback($RadiusScaler/Circle, 0.08, "hide")
	$Tween.interpolate_callback($RadiusScaler/Shockwave, 0.03, "show")
	$Tween.interpolate_property($RadiusScaler/Shockwave, "scale", $RadiusScaler/Shockwave.scale*0.1, $RadiusScaler/Shockwave.scale, 0.35, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$Tween.interpolate_property($RadiusScaler/Shockwave.material, "shader_parameter/multiplier", 1.0, 0.0, 0.35, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$Tween.start()
	$Sparks.restart()

func _on_SelfDestructionTimer_timeout():
	queue_free()
