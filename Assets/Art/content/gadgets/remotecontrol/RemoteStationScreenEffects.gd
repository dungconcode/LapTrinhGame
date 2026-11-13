extends PanelContainer

@onready var mat :ShaderMaterial = $ColorRect.material
var tw
var on_amount := 1.0

func _ready():
	Data.listen(self, "stationextension.resolution",true)

func propertyChanged(property:String, oldValue, newValue):
	#stationextension.resolution
	mat.set_shader_parameter("resolution", int(newValue * 512))

func set_on_val(val):
	mat.set_shader_parameter("on_amount",val)
	on_amount = val


func fade_in():
	if tw:
		tw.kill()
	tw = create_tween()
	#$ShaderSound.play()
	tw.tween_method(set_on_val,on_amount,1.0,0.5)
	
	
func fade_out():
	if tw:
		tw.kill()
	
	tw = create_tween()
	tw.tween_method(set_on_val,on_amount,0.0,0.5)
	#$ShaderSound.stop()

func set_effects_active(val):
	mat.set_shader_parameter("active",val)
	Data.event("event.keepers.remotestationeffectsactive",not val, val)

func set_visible(val):
	$ColorRect.visible = val
