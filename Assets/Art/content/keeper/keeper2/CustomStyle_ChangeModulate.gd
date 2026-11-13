extends Node2D

@export var self_init: bool = false
@export var styleColor: Color = Color("#208928")


func _ready():
	if not is_in_group("customStyle"):
		add_to_group("customStyle")
	if self_init:
		Style.init(self)


func updateStyleColor():
	modulate = Style.mapColor(styleColor)
