extends Control

class_name HudElement

signal request_rebuild

@export var element_size := Vector2()
@export var layoutWeights := Vector2()
@export var layoutPriority := 0

# if this hud element is supposed to work per keeper, the playerId needs to be set so it can access it
var playerId:String

func _ready():
	Style.init(self)

func init():
	pass
