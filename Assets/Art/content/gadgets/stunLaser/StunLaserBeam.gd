extends Line2D

func _ready():
	$HitEffect.visible = false
	$HitParticles.emitting = false

func shootAt(pos:Vector2):
	set_point_position(1, pos)
	$HitEffect.visible = true
	$HitEffect.position = pos
	$HitParticles.position = pos
	if not $HitParticles.emitting:
		$HitParticles.amount = 10
		$HitParticles.emitting = true

func stopShooting():
	set_point_position(1, get_point_position(0))
	$HitParticles.emitting = false
	$HitEffect.visible = false

func setStage(i):
	$HitEffect.play(str(i))
	$HitParticles.process_material.initial_velocity_min = 35 + 15 * int(i)
	$HitParticles.amount = 5 + int(i) * 5
