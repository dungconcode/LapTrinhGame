extends Node2D

@onready var electrifiedSurfaceParticles = $ElectrifiedSurfaceParticles
var active := false

func _ready():
	hide()
	set_process(false)
	Data.listen(self, "dome.electrifiedsurface")
	Data.listen(self, "monsters.wavepresent")


func propertyChanged(property:String, oldValue, newValue):
	match property:
		"monsters.wavepresent":
			active = newValue
			electrifiedSurfaceParticles.emitting = active
		"dome.electrifiedsurface":
			if newValue:
				show()
				set_process(true)


func _process(delta):
#	if not active:
#		return
	var particlePos : Vector3 = Level.dome.getCupolaPosition(wrapf(Time.get_ticks_msec()/100.0, 0.05, 0.97))
	electrifiedSurfaceParticles.global_position = Vector2(particlePos.x, particlePos.y)+Vector2(0, -10).rotated(particlePos.z)
	electrifiedSurfaceParticles.rotation = particlePos.z
