extends Node2D

@export var mask : Texture2D = null: set = set_mask

func _ready():
	if not Engine.is_editor_hint():
		Style.init(self)
		visible = false
	
func set_mask(value):
	mask = value
	if Engine.is_editor_hint():
		$Flash.texture = mask
	
func start():
	$Flash.texture = mask
	var duration = 5.0
	
	$Tween.remove_all()
	$Tween.interpolate_method(self, "flash", 0, 1.0, duration / 2.0, Tween.TRANS_CIRC, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, duration, "hide")
	$Tween.start()

	visible = true

func flash(value):
	var m = $Flash.material as ShaderMaterial
	m.set_shader_parameter("t",value)
