extends Sprite2D

@export var debug_mode := false

func _ready():
	if debug_mode:
		modulate.a = 1.0
		use_parent_material = true
