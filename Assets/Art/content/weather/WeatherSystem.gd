extends Node2D

@export var enabled := false
@export var ClearPercentage: int = 50 # (int, 0, 100)
@export var Lightning: bool = true
@export var Fog: bool = true
@export var Rain: bool = true
@export var Snow: bool = true
@export var Meteors: bool = true
@export var Spores: bool = true

var WEATHER = [
	[preload("res://content/weather/lightning/LightningStorm.tscn")],
	[preload("res://content/weather/fog/Fog.tscn")],
	[preload("res://content/weather/rain/Rain.tscn")],
	[preload("res://content/weather/rain/Rain.tscn"), preload("res://content/weather/lightning/LightningStorm.tscn")],
	[preload("res://content/weather/snow/Snow.tscn")],
	[preload("res://content/weather/meteor/meteorshower.tscn")],
	[preload("res://content/weather/spores/spores.tscn")],
	[preload("res://content/weather/windstorm/windstorm.tscn")],
]

func _ready():
	if not enabled:
		queue_free()

func get_weather_system() -> Array:
	if randf() <= float(ClearPercentage)/100.0:
		return []

	var weather = []
	if Lightning:
		weather.append(WEATHER[0])
	
	if Fog:
		weather.append(WEATHER[1])
	
	if Rain and not GameWorld.isChristmas:
		weather.append(WEATHER[2])
		if Lightning: 
			weather.append(WEATHER[3])
	
	if Snow or GameWorld.isChristmas: 
		weather.append(WEATHER[4])
	
	if Meteors: 
		weather.append(WEATHER[5])
	
	if Spores: 
		weather.append(WEATHER[6])
	
	var w = []
	if weather.size():
		weather.shuffle()
		for scene in weather[0]:
			w.append(scene.instantiate())

	return w

func _on_changeWeatherTimer_timeout():
	clear_current_weather()
	if not enabled:
		return
	
	var weather = get_weather_system()
	for w in weather:
		add_child(w)

func set_weather(index):
	clear_current_weather()
		
	for scene in WEATHER[index]:
		var w = scene.instantiate()
		add_child(w)

func clear_current_weather():
	for w in get_tree().get_nodes_in_group("weather"):
		if is_instance_valid(w) and w.has_method("stop"):
			w.stop()

func pauseChanged():
	$changeWeatherTimer.paused = GameWorld.paused
