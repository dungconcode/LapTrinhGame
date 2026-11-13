extends Node2D

var FogLayer = preload("res://content/weather/fog/FogLayer.tscn")

func _ready():
	Style.init(self)
	start_weather()
	
func start_weather():
	var fog_instances = 0
	var possible_positions = []
	var direction: Vector2
	
	match randi() % 3:
		0:
			direction = Vector2.UP
		1:
			direction = Vector2.RIGHT
		2:
			direction = Vector2.LEFT
			
	# Instance near and far fog
	var fog_speed = randf_range(10, 40)
	
	possible_positions = get_tree().get_nodes_in_group("weather-fognear")
	if possible_positions.size():
		var fog = FogLayer.instantiate()
		fog.direction = direction
		fog.speed = fog_speed
		possible_positions[0].add_child(fog)
		fog_instances += 1

	# Instance near and far fog
	possible_positions = get_tree().get_nodes_in_group("weather-fogfar")
	if possible_positions.size():
		var fog = FogLayer.instantiate()
		fog.direction = direction
		fog.speed = fog_speed/2.0
		possible_positions[0].add_child(fog)
		fog_instances += 1
		
	if fog_instances == 0:
		queue_free()
		
func stop():
	queue_free()
