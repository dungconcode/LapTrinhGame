extends Node2D

var monsters = {}

const Hit = preload("res://content/gadgets/cobaltbomb/CobaltHit.tscn")
const Flash = preload("res://content/gadgets/cobaltbomb/CobaltFlash.tscn")
const GroundBurst = preload("res://content/gadgets/cobaltbomb/GroundBurst.tscn")

func _ready():
	# All timing is controlled by the animation player
	$AnimationPlayer.play("boom")
	$sfxBomb.play()
	Style.init(self)

func _process(delta):
	# Update the line renderer positions
	for monster in monsters.keys():
		var line = monsters[monster]["line"] as Line2D
		var flash = monsters[monster]["flash"] as Node2D
		if not is_instance_valid($Orbs):
			line.hide()
			continue
		if not is_instance_valid(monster):
			line.hide()
			continue
		var direction = (monster.global_position - $Orbs.position).normalized()
		line.set_point_position(0, $Orbs.position)
		
		line.set_point_position(1, monster.global_position)
		flash.global_position = to_global(monster.global_position)
		flash.rotation = direction.angle()
		if line.default_color == Color("#ffffff"):
			line.width = 2
			line.default_color = Color("#804B6B")
		else:
			line.width = 4
			line.default_color = Color("#ffffff")
		monster.hit("cobaltbomb", 0.001 * delta, 10)

func explode():
	# Shake shake shake
	InputSystem.shake(400, 10, 8, global_position)
	
	# Destroy all monsters
	for monster in monsters.keys():
		var line = monsters[monster]["line"] as Line2D
		line.hide()
				
		if not is_instance_valid(monster):
			continue
			
		var hit = Hit.instantiate()
		hit.global_position = monster.global_position
		
		var delay = randf_range(0.2, 1.0)
		$Tween.interpolate_callback(self, delay - 0.1, "add_child", hit)
		$Tween.interpolate_callback(self, delay, "kill_monster", monster)
		
	$Tween.start()
	$monsterScanTimer.stop()

# Add ground bursts
func ground_bursts():
	for n in range(5):
		var delay = n * 0.1
		var burst1 = GroundBurst.instantiate()
		burst1.position = n * Vector2(80, 0) + Vector2(75, -64)
		var burst2 = GroundBurst.instantiate()
		burst2.position = n * Vector2(-80, 0) + Vector2(-75, -64)
		$Tween.interpolate_callback(self, delay, "add_child", burst1)
		$Tween.interpolate_callback(self, delay, "add_child", burst2)

	$Tween.start()
		
func kill_monster(monster):
	if not is_instance_valid(monster):
		return
	
	monster.invulnerable = false
	monster.hittable = true
	monster.hit("cobaltbomb", 100000, 100000)
	
	# Hide the line renderer
	var line = monsters[monster]["line"]
	line.hide()

	# Destroy all projectiles
	for p in get_tree().get_nodes_in_group("projectile"):
		p.deactivate()

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()

func start_monster_scan():
	$monsterScanTimer.start()
	
# Scan for monsters and add them to the monsters dictionary
# for later destruction
func _on_monsterScanTimer_timeout():
	for monster in get_tree().get_nodes_in_group("monster"):
		if monsters.has(monster):
			continue
		var line = Line2D.new()
		line.add_point($Orbs.position)
		line.add_point(monster.position)
		add_child(line)
		var flash = Flash.instantiate()
		line.add_child(flash)
		monsters[monster] = { "line": line, "flash": flash }
		Style.init(line)
