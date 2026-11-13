extends Area2D

var damage := 0.0


func _ready():
	var bullet = preload("res://content/weapons/artillery/BulletImpactExplosionVfx.tscn").instantiate()
	bullet.position = global_position
	bullet.rotation = rotation
	Level.map.addPixelEffect(bullet)
	await get_tree().physics_frame
	applyDamage()


func applyDamage():
	for area in get_overlapping_areas():
		if area.is_in_group("monster"):
			area.hit("artillerymachinegun1", damage, damage * 0.5)
	queue_free()
