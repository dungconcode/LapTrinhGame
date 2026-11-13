extends Node2D

var _texture: Texture2D

func _ready():
	$CPUParticles2D.emitting = true


func set_texture(value:Texture2D, flipped:bool, hframes:int, frame:int):
	_texture = value
	if _texture == null:
		return
		
	# Scan texture for pixels
	var pixels: PackedVector2Array = []
	var colors: PackedColorArray = []
	
	var image = _texture.get_image()
	var width = _texture.get_width() / hframes
	var startX = frame * width
	var height = _texture.get_height()
	for x in range(width):
		for y in range(height):
			var c = image.get_pixel(startX+x, y)
			var v = Vector2(x-width/2, y-height/2)
			if flipped:
				v.x = -v.x
			if c.a > 0:
				pixels.append(v)
				colors.append(c)
	
	# Apply those points to the particle emitter
	$CPUParticles2D.emission_points = pixels
	$CPUParticles2D.emission_colors = colors
	$CPUParticles2D.amount = pixels.size()


func get_texture() -> Texture2D:
	return _texture


func _on_cpu_particles_2d_finished() -> void:
	queue_free()
