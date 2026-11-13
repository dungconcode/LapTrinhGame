extends Node2D

@export var light_name:String				= "default"
@export var light_color:Color				= Color.WHITE
@export var light_expansion:float			= 3.0
@export var light_size:float					= 64.0: set = set_light_size
@export var light_precision:int				= 144
@export var light_active:bool				= true: set = set_light_active
@export var light_flicker_strength:float		= 0.0
@export var light_flicker_speed:float		= 1.0

var flicker_tween:Tween
var flicker_expansion:float					= 0.0
var rays:Array[LightRayCast] = []
var skip_frame := 0
var is_on_screen := true
var frames_to_skip := 0
var points := {}
var visibility_notifier := VisibleOnScreenNotifier2D.new()

@onready var orig_color:Color				= light_color

class LightRayCast:
	var parent : Node2D
	var dir : Vector2
	var ray : RayCast2D
	var light_range : float:
		set(f):
			light_range = f
			ray.target_position = dir*light_range
	var enabled := true:
		set(b):
			enabled = b
			ray.enabled = b
	func _init(_parent:Node2D, _dir:Vector2, _light_range:float) -> void:
		parent = _parent
		ray = RayCast2D.new()
		dir = _dir
		light_range = _light_range
		ray.enabled = true
		parent.add_child(ray)
	
	func get_hit(light_expansion:float, flicker_expansion:float) -> Vector2:
		var hit_point:Vector2 = Vector2.ZERO
		if ray.is_colliding():
			hit_point = ray.get_collision_point() - parent.global_position
		else:
			hit_point = ray.target_position.rotated(ray.rotation)
		var distance:float = hit_point.length() + light_expansion
		return dir * (distance + flicker_expansion)

func _enter_tree():
	add_to_group("customStyle")

func _ready() -> void:
	Style.init(self)
	light_name += "_" + str(get_instance_id())
	var angle_slice:float = TAU/light_precision
	for i in light_precision:
		var los_ray := LightRayCast.new(self, Vector2.RIGHT.rotated(angle_slice*float(i)), light_size)
		rays.append(los_ray)
	if light_flicker_strength > 0.0:
		flicker_tween = create_tween()
		flicker_tween.finished.connect(start_flicker)
		start_flicker()
	
	visibility_notifier.rect = Rect2(-light_size*1.5, -light_size*1.5, light_size*3.0, light_size*3.0)
	visibility_notifier.screen_entered.connect(_on_screen_entered)
	visibility_notifier.screen_exited.connect(_on_screen_exited)
	add_child(visibility_notifier)
	
	frames_to_skip = 2 if Options.renderHalfRes else 0
	Data.listen(self, "options.changed")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"options.changed":
			frames_to_skip = 2 if Options.renderHalfRes else 0

func _on_screen_entered():
	is_on_screen = true
	if light_active:
		for ray:LightRayCast in rays:
			ray.enabled = true

func _on_screen_exited():
	is_on_screen = false
	for ray:LightRayCast in rays:
		ray.enabled = false

func set_light_size(new_size:float):
	light_size = new_size
	for ray:LightRayCast in rays:
		ray.range = light_size

func updateStyleColor():
	light_color = Style.mapColor(orig_color)

func start_flicker():
	var strength: float = randf_range(light_flicker_strength, light_flicker_strength*2)
	if flicker_tween:
		flicker_tween.kill()
	flicker_tween = create_tween()
	flicker_tween.tween_property(self, "flicker_expansion", strength, 0.08*light_flicker_speed)
	flicker_tween.finished.connect(start_flicker)

func set_light_active(value:bool):
	if light_active == value:
		return
	light_active = value
	if visibility_notifier.is_on_screen():
		for ray:LightRayCast in rays:
			ray.enabled = light_active
	if not light_active and Level.map:
		Level.map.lights.remove_light(light_name)

func _physics_process(delta):
	if not light_active or not is_on_screen:
		return
	if skip_frame <= 0:
		skip_frame = frames_to_skip
		points.clear()
		for light_ray:LightRayCast in rays:
			var new_point:Vector2 = light_ray.get_hit(light_expansion, flicker_expansion)
			points[new_point.round()*global_scale] = null
	else:
		skip_frame -= 1
	
	if Level.map:
		Level.map.lights.update_light_poly(light_name, points.keys(), light_color, global_position)
