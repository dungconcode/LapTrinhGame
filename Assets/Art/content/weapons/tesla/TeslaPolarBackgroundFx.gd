extends Sprite2D

var currentScale := 1.0

@onready var mat : Material = material

var power := 0.0


func _ready():
	mat = material.duplicate()
	material = mat
	mat.set_shader_parameter("palette", Style.palette)


func setPower(newPower:float):
	power = newPower
	mat.set_shader_parameter("extra_power", newPower)


func setScale(newScale:float):
	scale = Vector2.ONE*newScale
	newScale = clamp(ease(clamp(newScale, 1, 15)/15.0, 0.3)*15.0, 5.0, 15.0)
	if abs(currentScale-newScale)<0.5:
		return
	currentScale = newScale
	mat.set_shader_parameter("uv_mod", Vector2(1, remap(newScale, 5, 15, 0.0, 1.0)))
	mat.set_shader_parameter("effect_scale", remap(newScale, 5, 15, 0.2, 1.2))
	mat.set_shader_parameter("effect_repeat", remap(newScale, 5, 15, 0.2, 2.5))
	mat.set_shader_parameter("noise_scale", remap(newScale, 5, 15, 0.1, 0.02))
	mat.set_shader_parameter("noise_size", remap(newScale, 5, 15, 0.5, 3))
	mat.set_shader_parameter("pulse_intensity", remap(newScale, 5, 15, 0.05, 0.01))


func end():
	$Tween.interpolate_method(self, "setScale", scale.x, 0.01, 0.27, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_method(self, "setPower", power, 0.01, 0.27, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, 0.3, "queue_free")
	$Tween.start()
