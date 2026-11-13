extends Node2D

@onready var slash = $Slash
@onready var flames = $Flames


func _ready():
	Style.init(self)
	$Slash2.frame = 0
	$Slash2.play()
	$Slash3.frame = 0
	$Slash3.play()
	
	$Tween.interpolate_callback($Slash, 0.05, "set_frame", 0)
	$Tween.interpolate_callback($Slash, 0.05, "play")
	$Tween.interpolate_callback($Flames, 0.1, "set_frame", 0)
	$Tween.interpolate_callback($Flames, 0.1, "play")
	
	$Tween.interpolate_callback($Smoke, 0.1, "restart")
	$Tween.interpolate_callback($Sparks, 0.1, "restart")
	$Tween.interpolate_callback(self, 3, "queue_free")
	$Tween.start()
