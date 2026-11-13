extends GPUParticles2D

func _ready():
	Style.init(self)

func _on_Timer_timeout():
	queue_free()

func set_size(size: float, spread: float = 1.0):
	process_material = process_material.duplicate()
	(process_material as ParticleProcessMaterial).scale *= size
	(process_material as ParticleProcessMaterial).emission_box_extents *= spread
