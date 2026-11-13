extends Node2D

var removable := 2
@export var damage := 50.0
@export var stun := -1.0
@export var damageSource: String

func _ready():
	$Sprite2D.frame = 0
	$Sprite2D.play()
	$Sound.play()
	Style.init(self)
	$Area2D/Collision.disabled = true
	if stun == -1:
		stun = damage * 0.1
	
	InputSystem.shake(10 + damage, 0.35, 16, global_position)

func _process(delta):
	if removable <= 0:
		queue_free()

func _on_Sprite_animation_finished():
	removable -= 1
	$Sprite2D.visible = false

func _on_Sound_finished():
	removable -= 1

func _on_Area2D_area_entered(area):
	area.hit(damageSource, damage, stun)

func _on_Sprite_frame_changed():
	if $Sprite2D.frame == 1:
		$Area2D/Collision.disabled = false
	elif $Sprite2D.frame == 4:
		$Area2D/Collision.disabled = true

func setRadius(r:float):
	if $Area2D/Collision.shape is CircleShape2D:
		$Area2D/Collision.shape.radius = r
