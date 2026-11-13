extends Drop

var countDown := 50.0
var settling := false
var hatching := false
var hatched := false

var forcePetId:String

func _ready():
	super._ready()
	Achievements.addIfOpen(self, "PET_FOUND")
	
	Data.listen(self, "inventory.totalrelic")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"inventory.totalrelic":
			if newValue > 0:
				countDown = 0.0

# called by EggGropPoint.gd
func grow():
	if not (hatched or hatching):
		settling = true

func settled():
	$Sprite2D.play("rooting")
	disablePhysics()
	hatching = true
	settling = false
	position.x = round(position.x)
	position.y = round(position.y)

func disablePhysics():
	z_index = 3
	$CollisionShape2D.disabled = true
	deactivate()
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	freeze = true
	set_physics_process(false)

func _physics_process(delta):
	super._physics_process(delta)
	if settling:
		if linear_velocity.length() < 1.0 and abs(rotation_degrees) < 3.0:
			settled()

func hatch():
	var petId:String
	if forcePetId and forcePetId != "":
		petId = forcePetId
	elif GameWorld.unlockablePets.size() == 0:
		if not GameWorld.unlockedPets.has("pet8"):
			# fix for lunar new year savegames
			petId = "pet8"
		else:
			$Sprite2D.play("broken")
			hatching = false
			hatched = true
	else:
		petId = GameWorld.unlockablePets[randi() % GameWorld.unlockablePets.size()]
	
	if petId:
		var pet = load("res://content/pets/" + petId + "/" + Data.startCaptialized(petId) + ".tscn").instantiate()
		Level.dome.add_child(pet)
	$Sprite2D.play("broken")
	hatching = false
	hatched = true

func _process(delta):
	if hatching and not hatched:
		if GameWorld.devMode and Input.is_action_just_pressed("f4"):
			hatch()

		if countDown > 0.0:
			countDown -= delta
			return

		for keeper in Keepers.getAll():
			if keeper.global_position.y < 400:
				return

		hatch()

func serialize()->Dictionary:
	var data = super.serialize()
	data["countDown"] = countDown
	data["settling"] = settling
	data["hatched"] = hatched
	data["hatching"] = hatching
	data["forcePetId"] = forcePetId
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	countDown = data["countDown"]
	settling = data["settling"]
	hatching = data.get("hatching", false)
	hatched = data["hatched"]
	forcePetId = data["forcePetId"]

	if hatched:
		$Sprite2D.play("broken")
		disablePhysics()
	elif hatching:
		$Sprite2D.play("rooting")
		disablePhysics()
