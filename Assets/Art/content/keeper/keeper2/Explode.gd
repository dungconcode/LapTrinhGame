extends AnimatedSprite2D

const RAY_COUNT = 3
var rays = []
var original_position
var oscillate_scale = 1.0

var playerId:String

func _ready():
	original_position = position
	Style.init(self)
	
	phase1()
	$Tween.interpolate_callback(self, 1.0, "phase2")
	$Tween.interpolate_property(self, "rotation", rotation, PI, 2.0, Tween.TRANS_BACK, Tween.EASE_IN, 2.0)
	$Tween.interpolate_property(self, "rotation", PI, 3.5 * TAU, 2.0, Tween.TRANS_CUBIC, Tween.EASE_OUT, 4.0)
	$Tween.interpolate_callback(self, 6.0, "phase3")
	$Tween.interpolate_property(self, "scale", scale, Vector2.ZERO, 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT, 6.0)
	$Tween.interpolate_callback(self, 7.0, "queue_free")
	
	oscillate_scale = 2.0
	$Tween.interpolate_property(self, "oscillate_scale", oscillate_scale, 0.0, 2, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()

func phase1():
	play("prepare")

func phase2():
	play("implode")
	var angle = randf() * TAU
	for _i in RAY_COUNT:
		var r = RayCast2D.new()
		var radius = Data.of(playerId + ".keeper2.explodespheresradius")
		r.target_position = Vector2(radius * GameWorld.TILE_SIZE, 0).rotated(angle)
		angle += TAU / float(RAY_COUNT)
		r.set_collision_mask_value(CONST.LAYER_TILE_COLLISION, true)
		r.enabled = true
		var line = Line2D.new()
		line.width = 3
		line.texture = preload("res://content/keeper/keeper2/player1/implode_ray.png")
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.material = preload("res://content/keeper/keeper2/ray_material.tres")
		line.material = line.material.duplicate()
		line.material.set_shader_parameter("speed", 7.0)
		line.material.set_shader_parameter("scale", 1.0)
		Style.init(line)
		add_child(r)
		add_child(line)
		rays.append({
			"ray": r,
			"line": line,
		})

func phase3():
	$GPUParticles2D.emitting = false
	for ray in rays:
		ray.line.visible = false
			
func _physics_process(delta):
	if GameWorld.paused:
		return
	
	var oscillate1 = sin(Time.get_ticks_msec() / 93)
	oscillate1 += sin(Time.get_ticks_msec() / 307)
	var oscillate2 = sin(Time.get_ticks_msec() / 37)
	oscillate1 += sin(Time.get_ticks_msec() / 233)
	var offset = Vector2(2,0) * oscillate1 * oscillate_scale
	offset += Vector2(0,2) * oscillate2 * oscillate_scale
	position = original_position + offset
	
	$RayParticles.emitting = false
	rays.shuffle()
	for ray in rays:
		var r: RayCast2D = ray.ray
		var line: Line2D = ray.line
		line.points = [Vector2.ZERO, r.target_position]
		if r.is_colliding():
			var tile = r.get_collider()
			var dir = -r.target_position.rotated(rotation).normalized()
			if tile and tile.get("max_health") and Data.isDestructable(tile):
				tile.hit(dir, tile.max_health * delta * 3.0)
				line.points[1] = to_local(r.get_collision_point())
				$RayParticles.global_position = r.get_collision_point()
				$RayParticles.global_rotation = (global_position - r.get_collision_point()).angle()
				$RayParticles.emitting = true

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()
