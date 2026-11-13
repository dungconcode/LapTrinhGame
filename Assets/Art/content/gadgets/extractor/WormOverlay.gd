extends Node2D

var playing := false

func _ready() -> void:
	var speed = Data.of("extractor.wormanimationspeed")
	Style.init(self)
	var children = get_children()
	var child = children.pick_random()
	children.erase(child)
	child.queue_free()
	var t = create_tween()
	var i = 1
	for c in children:
		c.flip_h = randf() > 0.5
		c.modulate.a = 0.0
		c.speed_scale = speed
		t.tween_property(c, "modulate:a", 1.0, 0.15 / speed).set_delay(randf_range(0.01, 1.0) / speed)
		c.play("pos" + str(i) + "_idle")
		i += 1

func _on_animated_sprite_animation_finished(i:int) -> void:
	if not playing:
		return
	
	var node = get_node("AnimatedSprite" + str(i))
	if node.animation.ends_with("idle"):
		return
	
	var children = get_children()
	children.erase(node)
	var animatedChild = children.pick_random()
	animatedChild.play("pos" + str(animatedChild.get_index() + 1) + ("_pass" if randf() > 0.5 else "_peek"))

func removeFromTile():
	var speed = Data.of("extractor.wormanimationspeed")
	var t = create_tween()
	for c in get_children():
		t.tween_property(c, "modulate:a", 0.0, 0.15 / speed).set_delay(randf_range(0.2, 2.0) / speed)
	t.tween_callback(queue_free)

func play():
	var starter = get_children().pick_random()
	starter.play("pos" + str(starter.get_index() + 1) + "_pass")
	playing = true

func stop():
	playing = false

func serialize()->Dictionary:
	var data = {
	}
	return data
	
func deserialize(data: Dictionary):
	pass
