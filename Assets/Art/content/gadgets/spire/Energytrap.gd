extends Area2D

# area should stay very long but have an energy
# energy gets drained by stunning monsters, or absorbing projectils

var initialEnergy:float
var remainingEnergy:float
var factor:float
var initialRadius:float
var lifetime:float
var removing := false

func _ready():
	$Sprite2D.scale *= 0.0
	$Sprite2D.material = $Sprite2D.material.duplicate()
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()

func start(projectileDamage:float):
	factor = sqrt(projectileDamage) / 6
	initialRadius = clamp(Data.of("spire.stuntrapradius") * factor, 15, 60)
	initialEnergy = Data.of("spire.stuntrapabsorption") * factor * projectileDamage
	remainingEnergy = initialEnergy
	
	# 1.1 better fits the collision radius with the shaderered effect. If changing effect, check that collision shape and effect match size
	lifetime = Data.of("spire.stuntrapduration") * max(0.7, factor)
	$Tween.interpolate_method(self, "setRadius",  0.0, initialRadius, 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$Tween.start()

func setRadius(radius):
	$CollisionShape2D.shape.radius = radius
	$Sprite2D.material.set_shader_parameter("pixelation_factor", radius * 2 * 1.45)
	$Sprite2D.scale = Vector2(1.45, 1.45) / ($Sprite2D.texture.get_size() / (radius * 2))

func _physics_process(delta):
	if GameWorld.paused or removing:
		return
	
	if lifetime > 0.0:
		lifetime -= delta
	
	if lifetime <= 0:
		remove()
		return
	
	if monitoring and Data.of("spire.stunmonsters"):
		for m in get_overlapping_areas():
			if m.is_in_group("monster"):
				m.hit("spirestuntrap3", 0, 5, true)
				lifetime -= delta * 2.0

func _on_Stuntrap_area_entered(area):
	if not area.is_in_group("monster") and remainingEnergy > 0.0:
		area.domeAbsorbsDamage()
		remainingEnergy -= area.damage
		if remainingEnergy <= 0.0:
			remove()
		else:
			var start = $CollisionShape2D.shape.radius
			var end = initialRadius * max(0.7, remainingEnergy / initialEnergy)
			$Tween.interpolate_method(self, "setRadius", start, end, 0.1)
			$Tween.start()

func remove():
	if removing:
		return
	
	removing = true
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_method(self, "setRadius", $CollisionShape2D.shape.radius, 0.0, 0.2 , Tween.TRANS_QUAD, Tween.EASE_IN)
	$Tween.interpolate_callback(self, 0.21, "queue_free")
	$Tween.start()
