extends Sprite2D

@export var light: Node
@onready var keeper = get_parent()

var scale_mod_target := 0.3
var scale_mod = 0.3

func _process(delta):
	scale_mod_target = 1.0 if not keeper.isInsideDome else 0.3
	scale_mod = lerp(scale_mod, scale_mod_target, delta*2.0)
	scale = Vector2.ONE * (1.0 + light.flicker_expansion*0.07) * scale_mod


func setGlow(value:float):
	self_modulate.a = lerp(0.2, 0.4, value)
