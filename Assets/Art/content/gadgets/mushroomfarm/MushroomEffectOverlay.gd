extends ColorRect

var current_intensity := 0.0
var tw

func set_intensity(value:float):
	
	if current_intensity == value:
		if current_intensity == 0.0:
			visible = false
		return
	
	if value > 0:
		visible = true
	
	if tw:
		tw.kill()
	
	tw = create_tween()
	
	tw.tween_method(func(x):
		current_intensity = x
		(material as ShaderMaterial).set_shader_parameter("intensity", float(x))
		,current_intensity,value, abs(value-current_intensity))
	
	tw.tween_callback(func(): 
		if value == 0:
			visible = false
		)
