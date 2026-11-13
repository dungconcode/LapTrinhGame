extends Node2D

var target: Vector2

func _ready():
	var angle = global_position.angle_to_point(target)
	rotation = angle
	
	#var length = (target - global_position).length()
	#$GPUParticles2D.position.x = length/2
	#$GPUParticles2D.process_material.emission_box_extents.x = length/2
	# TODO turn off for trailer? Special cases like dropping all resources when entering the dome should be considered. For such cases, the effect might be too strong.  
#	$Particles2D.amount = length
#	$Particles2D.emitting = true
	
	Style.init(self)

	
func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
