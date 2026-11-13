extends Node2D

@export var scrollSpeeds := []
@export var enabled := true

func _ready():
	var z = -get_child_count() + 1
	for c in get_children():
		if c.z_index == 0:
			c.z_index = z
		z += 1

func _process(delta):
	if not enabled:
		return
	
	var cam = InputSystem.getCamera()
	if not cam:
		return
	
	var dy := 0.0
	# TODO Multiplayer - needs parallax back in
	dy = cam.position.y - cam.getCameraRestPosition(cam.zoom.x)
	for i in range(0, get_child_count()):
		var off = scrollSpeeds[i]
		var background = get_child(i)
		background.position.y = (1.0-off) * dy
#	$Foreground02.material.set_shader_param("fade_x", clamp(-0.05 + dy * 0.002 - max(0,dy-180)*0.004, 0.0, 0.1))
#	$Foreground01.material.set_shader_param("fade_y", clamp(0.82 + dy * 0.00066, 0.0, 1.0))
