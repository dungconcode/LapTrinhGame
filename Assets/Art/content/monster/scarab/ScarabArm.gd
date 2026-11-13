extends "res://content/monster/Monster.gd"

var goalPos:Vector2
var variant:String
var path:Path2D
var progress
var speed:float
var delay := 0.2

func start(side:String, path:Path2D):
	self.variant = side
	self.path = path
	$Sprite2D.play(side)
	progress = randf_range(150,250)
	self.goalPos = path.curve.sample_baked(progress) + path.global_position + Vector2(0, -10)
	speed = Data.of("scarabarm.speed") * randf_range(0.85, 1.15)

func subProcess(delta):
	if delay > 0.0:
		delay -= delta
		return
	
	var d = goalPos - position
	if d.length() < 3.0:
		grow()
		InputSystem.shake(80, 0.2, 8, global_position)
		set_physics_process(false)
		rotation = 0
		position += Vector2(-5, -5)
	else:
		var angle = d.angle()
		if angle > 0:
			rotation = d.angle() + PI * 1.6
		else:
			rotation = d.angle() - PI * 1.6
		position += (d.normalized() * delta * speed).limit_length(d.length())

func grow():
	$Sprite2D.play("grow")
	$GrowAndBurstSound.play()

func animateDeath():
	$Sprite2D.play("die")

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "grow" and $Sprite2D.frame == 13:
		var walker = preload("res://content/monster/mucker/Mucker.tscn").instantiate()
		walker.path = path
		Level.world.assignPathOccupation(Data.of("mucker.movetype"), path, walker)
		walker.meleeTarget = Level.dome.getMeleeTarget(variant)
		walker.progress = progress
		Level.monsters.registerMonster(walker)
		emit_signal("died") 

func _on_sprite_2d_animation_looped() -> void:
	_SpriteAnimationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_SpriteAnimationFinishedCheck()

func _SpriteAnimationFinishedCheck() -> void:
	if $Sprite2D.animation == "grow":
		queue_free()
	if $Sprite2D.animation == "die":
		removeFreeBlocker()


