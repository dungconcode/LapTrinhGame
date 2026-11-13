extends Node2D

var origin:Vector2
var goalPos:Vector2
var velocity := Vector2()
var speed:float
var speed_offset:float = randf_range(0.9, 1.1)
var cooldown := 0.0
var acceleration := 3.0
var buff:float
var time_on_position := 0.0
var noise_offset := 100000.0
var timeBetweenShots:float
var shotsRemaining:int
var returning := false
var anim_tween:Tween
var noise := FastNoiseLite.new()

@onready var sprite = $Sprite2D


func _ready():
	sprite.play("idle")
	origin = position
	goalPos = origin
	setBuff(buff)
	sprite.speed_scale = speed_offset
	Style.init(self)
	shotsRemaining = Data.ofOr("droneyard.battledroneshots",1)

func setBuff(buff:float):
	timeBetweenShots = 0.7 / (1.0 + buff)
	speed = (150 + 150 * buff) * speed_offset

func returToOrigin():
	goalPos = origin
	returning = true

func setGoalPosition(pos:Vector2):
	if not returning:
		goalPos = pos

func _physics_process(delta):
	if GameWorld.paused:
		return
	
	var direction = (goalPos - position).limit_length(speed)
	velocity = lerp(velocity, direction, delta * acceleration)
	position += velocity * delta
	
	var length = direction.length()
	
	if sprite.animation != "shoot":
		if length > 3.0:
			noise_offset = randf()*100000.0
			time_on_position = clamp(time_on_position-delta, 0.0, 1.0)
			if abs(direction.x) > abs(direction.y):
				if direction.x < 0:
					sprite.play("move_left")
				else:
					sprite.play("move_right")
			else:
				sprite.play("move")
		else:
			time_on_position += delta
			sprite.play("idle")
	
	if not anim_tween or not anim_tween.is_running():
		var noise_target_pos:Vector2 = Vector2(
			noise.get_noise_1d(noise_offset + time_on_position*7.0) * 2.0,
			noise.get_noise_1d(noise_offset + time_on_position*14.0 + 1000.0) * 4.0) * min(time_on_position, 1.0)
		sprite.position = lerp(sprite.position, sprite.position+noise_target_pos, delta*3.0)
	
	#dont allow shooting when mooving too fast
	if length > 20.0:
		return
	
	if returning:
		if direction.length() < 3.0:
			queue_free()
		return
	
	if cooldown > 0.0:
		cooldown -= delta
		return
	
	if shotsRemaining <= 0:
		returToOrigin()
		return
	
	var closestMonster = find_target()
	if closestMonster:
		var t := create_tween()
		t.tween_property(sprite, "position", Vector2.ZERO, 0.5)
		sprite.play("shoot")
		

func find_target():
	var closestMonster
	var closestDistance := 9999.0
	for monster in $TargetArea.get_overlapping_areas():
		if not can_target(monster):
			continue
		var dist = (monster.position - position).length()
		if dist < closestDistance:
			dist = closestDistance
			closestMonster = monster
	return closestMonster

func can_target(m) -> bool:
	return m != null and m.alive() and not m.invulnerable and m.canBeHit()

func fire_at(monster):
	var shot = preload("res://content/gadgets/droneyard/BattleDroneLaser.tscn").instantiate()
	shot.speed = 350
	$FireSound.play()
	shot.damageSource = "droneyardbattlegrid"
	shot.position = position
	shot.origin = position
	shot.target = monster
	shot.damage = Data.of("droneyard.battledroneshotdamage")
	shot.speed += shot.speed * buff
	
	if anim_tween:
		anim_tween.kill()
	anim_tween = create_tween()
	anim_tween.tween_property(sprite, "position", Vector2(2, -10), 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	anim_tween.tween_property(sprite, "position", Vector2.ZERO, 0.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	cooldown = timeBetweenShots
	shot.damage += shot.damage * buff
	Level.viewports.addElement(shot)
	shotsRemaining -= 1

func _on_sprite_2d_animation_finished() -> void:
	match sprite.animation:
		"shoot":
			sprite.play("idle")

func _on_sprite_2d_frame_changed() -> void:
	if sprite.animation == "shoot":
		if sprite.frame == 5:
			var mon = find_target()
			if mon:
				fire_at(mon)
