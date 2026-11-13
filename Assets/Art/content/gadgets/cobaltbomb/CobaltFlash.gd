extends Node2D

func _ready():
	$AnimatedSprite2D.play("flash")
	Style.init(self)
