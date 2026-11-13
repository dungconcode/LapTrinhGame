extends Sprite2D

@export var randomFlipH := false
@export var randX := Vector2()
@export var randY := Vector2()

var visibleAt:float
var visibility:float

func _ready():
	if randomFlipH:
		flip_h = randf() > 0.5
	
	if randX.length() > 0:
		offset.x = round(offset.x + randX.x + randf()*randX.y)
	if randY.length() > 0:
		offset.y = round(offset.y + randY.x + randf()*randY.y)
	
	set_process(false)
	frame = randi() % hframes
	
	visibleAt = randf()*1.3 # overshoot, so not all is being revealed
	visibility = 0.3
	if visibleAt <= visibility:
		visible = true
	else:
		visible = false
		if visibleAt <= 1.0:
			add_to_group("growing_decorations")

func flipH():
	offset.x = -offset.x
	flip_h = not flip_h

func dissolve():
	if get("texture") == null or not visible:
		queue_free()
		return

	# Instance dissolve node
	var dissolve = preload("res://content/map/decorations/Dissolve.tscn").instantiate()
	dissolve.position = position + offset
	dissolve.global_rotation = global_rotation
	dissolve.set_texture(texture, flip_h, hframes, frame)
	get_parent().add_child(dissolve)
	queue_free()

func progress():
	visibility += (1.2 - visibility) * 0.125
	
	if visibility > visibleAt:
		makeVisible()

func makeVisible():
	visible = true
	remove_from_group("growing_decorations")
	
