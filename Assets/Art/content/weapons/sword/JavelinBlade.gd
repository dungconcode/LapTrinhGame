extends Node2D

var hitMonsters := []
var piercedMonsters := []
var remainingPierceDamage:float
var hit_slowdown = 0.0
var bomb

var JavelinPieces = load("res://content/weapons/sword/JavelinPieces.tscn")

func _ready():
	set_physics_process(true)
	if Data.of("sword.stabarrowhead"):
		find_child("ArrowLeft", false, false).visible = true
		find_child("ArrowRight", false, false).visible = true

func _process(delta):
	if GameWorld.paused:
		return

	# Hit slowdown and flash effect
	var timer_normalized = $HitTimer.time_left / $HitTimer.wait_time
	if $HitTimer.is_stopped():
		timer_normalized = 0.0
		hit_slowdown = 0.0
	if timer_normalized > 0:
		modulate = Color(10,10,10,1)
	else:
		modulate = Color(1,1,1,1)
	if hit_slowdown <= 0.0 or timer_normalized < 1.0 - hit_slowdown:
		position += Vector2.UP.rotated(rotation) * Data.of("sword.extendSpeed") * Data.of("sword.stabspeed") * delta
		
	if hitMonsters.size() > 0:
		var hasHit := false
		for m in hitMonsters:
			if not piercedMonsters.has(m):
				if bomb and bomb.visible:
					var explosion = load("res://content/shared/explosions/DirectionalExplosion" + str(Data.of("sword.stabExplosive")) + ".tscn").instantiate()
					explosion.rotation = rotation - CONST.PI_HALF
					explosion.position = bomb.global_position
					explosion.damage = Data.of("sword.stabExplosiveDamage")
					get_parent().add_child(explosion)
					bomb.visible = false
				
				hasHit = true
				var dmg = min(remainingPierceDamage, m.currentHealth)
				m.hit("swordstabshoot", dmg, 5 * dmg)
				piercedMonsters.append(m)
				remainingPierceDamage -= dmg
				if dmg > 0 and remainingPierceDamage <= 0:
					var pos = $HitArea/BladeCollisionShape.global_position
					var rot = global_rotation
					var pieces = JavelinPieces.instantiate()
					m.add_child(pieces)
					pieces.start(pos, rot)
					queue_free()
				if dmg > 0:
					$HitTimer.start()
					hit_slowdown = 0.5 * float(dmg) / float(Data.of("sword.stabDamage"))
				elif remainingPierceDamage <= 0:
					queue_free()
		if hasHit:
			$HitSound.play()

func addBomb(b):
	add_child(b)
	bomb = b

func setCollisionShapes(bladeCollisionShape, arrowHead):
	$HitArea/BladeCollisionShape.position = bladeCollisionShape.position
	$HitArea/BladeCollisionShape.shape = bladeCollisionShape.shape
	$HitArea/ArrowHead.position = arrowHead.position
	$HitArea/ArrowHead.shape = arrowHead.shape

func _on_Timer_timeout():
	queue_free()

func _on_HitArea_area_entered(area):
	if area.is_in_group("monster"):
		addToHitMonsters(area)

func _on_HitArea_area_exited(area):
	if area.is_in_group("monster"):
		removeFromHitMonsters(area)

func addToHitMonsters(m):
	if not hitMonsters.has(m):
		hitMonsters.append(m)
		if not m.is_connected("died", Callable(self, "removeFromHitMonsters")):
			m.connect("died", Callable(self, "removeFromHitMonsters").bind(m))

func removeFromHitMonsters(m):
	if hitMonsters.has(m):
		hitMonsters.erase(m)
		m.disconnect("died", Callable(self, "removeFromHitMonsters"))
