extends Sprite2D

const sideLightEnergy = 1.5
const backLightEnergy = 0.5
const variance = 0.05
var rate = 0.15

var goalEnergySide := sideLightEnergy
var goalEnergyBack := backLightEnergy

func _physics_process(_delta):
	if Engine.get_physics_frames() % int(1.0/rate) == 0:
		var newGoal = randf()
		goalEnergySide = lerp(sideLightEnergy*(1.0-variance), sideLightEnergy+(1.0+variance), newGoal)
		goalEnergyBack = lerp(backLightEnergy*(1.0-variance), backLightEnergy+(1.0+variance), newGoal)
	$LightBack.energy = lerp($LightBack.energy, goalEnergyBack, rate)
	$Light3D.energy = lerp($Light3D.energy, goalEnergySide, rate)
	
	if Engine.get_physics_frames() % 60 == 0 and randf() < 0.2:
		$AnimationPlayer.play("flash")
