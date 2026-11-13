extends Node2D

var explosion = 0

func _ready():
	$AnimatedSprite2D.play()
	$SmokeParticles.emitting = true
	
	var t = DeprecatedTween.new()
	add_child(t)
	t.interpolate_callback(self, 1.0, "explode")
	t.interpolate_callback(self, 0.5, "explode")
	t.interpolate_callback(self, 30, "queue_free")
	t.start()
	
	$EngineSound.play()


func explode():
	var expl = load("res://content/shared/explosions/DirectionalExplosion1.tscn").instantiate()
	add_child(expl)
	expl.z_index = 100
	if explosion == 0:
		expl.position = Vector2(-60,0)
		expl.rotation = deg_to_rad(-110)
	if explosion == 1:
		expl.position = Vector2(60,0)
		expl.rotation = deg_to_rad(-70)
	explosion += 1
