extends Node2D

@export var show_eyes := false

var size := 0.0
var noise := preload("res://content/monster/bloater/fast_noise_lite.tres")
var violence := 1.0
var time := randf()*10000.0
var eye_thresholds := [randf_range(0.1, 0.3), randf_range(0.3, 0.5), randf_range(0.4, 0.6)]

@onready var sprites_positions = [%Sprite1.position, %Sprite2.position, %Sprite3.position]
@onready var  eyes = [%Eye1, %Eye2, %Eye3]

func _ready():
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	for e in eyes:
		e.hide()


func _process(delta):
	if GameWorld.paused or "stunned" in owner and owner.stunned:
		return
	time = wrapf(time + delta * violence * 15, 0.0, 10000.0)
	var rotation_speed = noise.get_noise_1d(time) * 4.0
	%Center.rotation = wrapf(%Center.rotation + delta * rotation_speed, -PI, PI)
	var i := 0
	for s in %Center.get_children():
		var noise_val = noise.get_noise_1d(time + i * 1000) * 2.0 + 2.0
		s.position = sprites_positions[i] * (size + 0.2) * 1.5 + Vector2.UP.rotated(noise_val * TAU) * noise_val * 0.5
		s.rotation = -%Center.rotation
		s.frame = round(clamp(size * (17 - violence * 0.2) + noise_val * violence * 0.2, 0.0, 18.0))
		if show_eyes:
			eyes[i].visible = size >= eye_thresholds[i]
			eyes[i].offset.x = -size * 10.0
		
		i += 1
	violence = max(violence - delta * 7.0, 1.0)

func set_material(mat):
	for s in %Center.get_children():
		s.material = mat

func hit():
	violence = 10.0
