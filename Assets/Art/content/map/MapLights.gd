extends SubViewport

var lights:Dictionary = {}
var pos_offset:Vector2 = Vector2(size.x/2, 50)
var map_to_world_offset:Vector2
var sprite:Sprite2D


func set_size(new_size:Vector2i):
	size = new_size
	pos_offset.x = size.x/2


func update_light_poly(light_name, points, light_color, light_position):
	if not light_name in lights:
		var new_light:Polygon2D = Polygon2D.new()
		add_child(new_light)
		lights[light_name] = new_light
		
	var light:Polygon2D = lights[light_name]
	light.color = light_color
	light.polygon = points
	light.position = light_position + pos_offset + map_to_world_offset


func remove_light(light_name):
	if light_name in lights:
		lights[light_name].queue_free()
		lights.erase(light_name)
