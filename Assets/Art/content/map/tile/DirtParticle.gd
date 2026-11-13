extends RigidBody2D

var tex_iron = preload("res://content/map/tile/tile-break-dirt-particle_iron.png")
var tex_water = preload("res://content/map/tile/tile-break-dirt-particle_water.png")
var tex_sand = preload("res://content/map/tile/tile-break-dirt-particle_sand.png")

var type:String = "default"

func _ready():
	var sprite = $Sprite2D
	if type != "default" and randf()>0.7:
		sprite.scale = Vector2.ONE * 0.7
		match type:
			CONST.SAND:
				sprite.texture = tex_sand
				Style.init(sprite)
			CONST.IRON:
				sprite.texture = tex_iron
				Style.init(sprite)
			CONST.WATER:
				sprite.texture = tex_water
				Style.init(sprite)
	sprite.frame = randi() % (sprite.hframes * sprite.vframes)
	sprite.modulate = Color.WHITE * randf_range(0.88, 1.05)
	sprite.modulate.a = 1.0
	sprite.scale = Vector2.ONE*(ease(randf()*0.5, 1.3)+0.7)
	
	var t := create_tween()
	t.tween_interval(randf_range(2.0, 3.0))
	t.tween_property(sprite, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	t.tween_callback(queue_free)
	
