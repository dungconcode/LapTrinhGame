extends Node2D

@export var progress := 0.5

@onready var impact_forks = $ImpactForks

var rot_timer := 0.0
var scale_mod := 0.4
func _process(delta):
	impact_forks.material.set_shader_parameter("progress", remap(ease(progress, 0.4), 0.0, 1.0, 0.9, 0.4))
	rot_timer += delta
	if rot_timer > 0.04:
		impact_forks.flip_h = randi()%2 == 0
		impact_forks.flip_v = randi()%2 == 0
		rot_timer -= 0.04
		impact_forks.rotation = randf()
		impact_forks.scale = Vector2.ONE*(scale_mod+randf_range(-0.1, 0.1))*0.4
