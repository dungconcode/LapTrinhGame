extends CPUParticles2D

const DirtParticle = preload("res://content/map/tile/DirtParticle.tscn")
var impactDirection:Vector2
var type:String
var dust_color: Color
var biome_color:Color
var spawn_dirt := true

func _ready():
	modulate = dust_color
	rotation = impactDirection.angle()
	restart()
	
	if spawn_dirt:
		var count := [7, 4] if not Options.lowFx else [3, 2]
		var dirt_count : int = get_tree().get_nodes_in_group("dirt_particles").size()
		if dirt_count > 200:
			return
		elif dirt_count > 130:
			count[0] = round(float(count[0]*0.3))
			count[1] = 1
		for _i in range(count[0]+randi()%count[1]):
			var t = DirtParticle.instantiate()
			t.type = type
			t.modulate = biome_color
			t.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			t.apply_central_impulse(impactDirection.rotated(randf_range(-0.6,0.6))*randf_range(-1,6))
			get_parent().call_deferred("add_child", t)


func _on_finished() -> void:
	queue_free()
