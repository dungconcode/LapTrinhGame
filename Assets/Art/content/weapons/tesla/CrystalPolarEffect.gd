extends Sprite2D

@onready var mat : Material = material

func _ready():
	mat.set_shader_parameter("palette", Style.palette)


func setPower(newPower:float):
	mat.set_shader_parameter("extra_power", newPower)
