extends Drop

var countDown := 30.0

var settling := false
var growing := false
var averageAngularVelocity := 0.0
var averageLinearVelocity := 0.0
var targetTile

func _ready():
	super._ready()
	$Roots.visible = false
	if isCarried():
		settling = false
	else:
		settling = true
	
	Level.addTutorial(self, "mineraltree")


func serialize()->Dictionary:
	var data = super.serialize()
	data["settling"] = settling
	data["growing"] = growing
	data["countDown"] = countDown
	if targetTile:
		data["targetTile"] = var_to_str(targetTile.coord)
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	settling = data["settling"]
	countDown = data["countDown"]
	if data["growing"]:
		$Roots.rotation = -rotation
		settled()
	if data.has("targetTile"):
		targetTile = Level.map.tiles[BackwardCompatibilityUtils.str_to_var(data["targetTile"])]
		targetTile.connect("destroyed", Callable(self, "onTargetTileDestroyed"))
	
func settled():
	$Roots.visible = true
	$Roots.frame = 0
	$Roots.play("rooting")
	$TreePlantSound.play()
	
	
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	freeze = true
	growing = true
	position.x = round(position.x)
	position.y = round(position.y)
	z_index = 1
	set_physics_process(false)

func onCarried(p:Keeper):
	if targetTile:
		targetTile.disconnect("destroyed", Callable(self, "onTargetTileDestroyed"))
		targetTile = null
	uprooted()

func onDropped(p:Keeper):
	settling = true
	countDown = 30

func uprooted():
	settling = false
	growing = false
	freeze = false
	set_physics_process(true)
	$Roots.visible = false

func _physics_process(delta):
	super._physics_process(delta)
	averageAngularVelocity = averageAngularVelocity * (1 - delta) + abs(angular_velocity*delta)
	averageLinearVelocity = averageLinearVelocity * (1 - delta) + linear_velocity.length() * delta
	if settling:
		if targetTile:
			var deltaX = targetTile.global_position.x - global_position.x
			if abs(deltaX) <= 0.1:
				if averageAngularVelocity < 0.3:
					settled()
			else:
				apply_central_impulse(Vector2(sign(deltaX) * (abs(deltaX) + 1), 0))
		elif averageLinearVelocity < 1.0:
			for i in get_colliding_bodies():
				if i is Tile \
					and (i.global_position.y > global_position.y or Data.ofOr("world.inversegravity", false))\
					and abs(global_position.x - i.global_position.x) <= GameWorld.TILE_SIZE * 0.5\
					and i.type != "border" \
					and i.health > 0: # needed because even after signaling it is destroyed, it still remains in physics for a bit
					
					targetTile = i
					targetTile.connect("destroyed", Callable(self, "onTargetTileDestroyed"))
					return
	
	$Roots.rotation = -rotation
	if Data.ofOr("world.inversegravity", false):
		$Roots.rotation += PI

func onTargetTileDestroyed():
	targetTile = null
	uprooted()
	settling = true # keep trying to grow still

func sprout():
	var tree = preload("res://content/gadgets/mineraltree/MineralTree.tscn").instantiate()
	tree.global_position = global_position
	tree.growOnTile(targetTile.coord)
	get_parent().add_child(tree)

func _process(delta):
	if growing:
		if GameWorld.devMode and Input.is_action_just_pressed("f4"):
			grow()
			return
		
		if countDown > 0.0:
			countDown -= delta
			return
		
		grow()

func grow():
	sprout()
	growing = false
	queue_free()
