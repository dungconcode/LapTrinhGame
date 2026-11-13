extends Node2D

const BEAM_LENGTH := 190.0

var frameTime := 0.0

@onready var part_1 = $Part1
@onready var part_2 = $Part1/Part2
@onready var start = $Start
@onready var end = $End

var target := Vector2.ZERO


func _process(delta):
	if not visible or GameWorld.paused:
		return
	# frames
	frameTime = wrapf(frameTime+delta*24.0, -0.5, 15.5)
	part_1.frame = round(frameTime)
	part_2.frame = part_1.frame
	start.frame = part_1.frame
	end.frame = part_1.frame
	
	# rotation
	look_at(target)
	
	# beam length
	end.global_position = target
	
	var dist:float= global_position.distance_to(target)
	if dist <= BEAM_LENGTH:
		part_2.hide()
		part_1.region_rect.size.x = dist
	else:
		part_2.show()
		part_1.region_rect.size.x = BEAM_LENGTH
		part_2.region_rect.size.x = dist-BEAM_LENGTH
