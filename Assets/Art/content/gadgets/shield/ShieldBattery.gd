extends "res://content/gadgets/PrimaryGadget.gd"

var currentFilling:float
var goalFilling:float
var offY := 0

var maxCharge:float

var batteryTextureNamePrefix:String

func _ready():
	match domeId:
		"dome1":
			$Background.texture = preload("res://content/gadgets/shield/batterie_laser_sheet.png")
			batteryTextureNamePrefix = "batterie-load"
			position += Vector2(-4, 1)
		"dome2":
			batteryTextureNamePrefix = "batterie-sword-load"
			$Background.texture = preload("res://content/gadgets/shield/batterie_sword_sheet.png")
			position += Vector2(-2, -5)
		"dome3":
			$Background.texture = preload("res://content/gadgets/shield/batterie_arty_sheet.png")
			batteryTextureNamePrefix = "batterie-load"
			position += Vector2(-1, 1)
		"dome4":
			batteryTextureNamePrefix = "batterie-tesla-load"
			$Background.texture = preload("res://content/gadgets/shield/batterie_tesla_sheet.png")
			position += Vector2(-3, -5)
	
	Data.listen(self, "shield.stage", true)
	Data.listen(self, "shield.maxstrength", true)
	Data.apply("shield.overcharged", false)
	Data.listen(self, "shield.overcharged")
	
	Level.addTutorial(self, "overcharge")
	
	Style.init(self)
	$Overcharge.visible = false

func serialize()->Dictionary:
	var data = {}
	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	data["currentFilling"] = currentFilling
	data["goalFilling"] = goalFilling
	data["offY"] = offY
	data["maxCharge"] = maxCharge
	data["stage"] = Data.of("shield.stage")
	return data

func deserialize(data: Dictionary):
	currentFilling = data["currentFilling"]
	goalFilling = data["goalFilling"]
	offY = data["offY"]
	maxCharge = data["maxCharge"]
	
	setStage(data["stage"])

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"shield.maxstrength":
			maxCharge = newValue
		"shield.stage":
			setStage(newValue)
		"shield.overcharged":
			$Overcharge.visible = newValue
			if newValue:
				$OverchargeAmbienceSound.play()
			else:
				$OverchargeAmbienceSound.stop()

func _process(delta: float) -> void:
	var currentShieldStrength = Data.of("shield.strength")
	var maxShieldStrength = Data.of("shield.maxStrength")
	
	var filling:float = currentShieldStrength / maxShieldStrength
	var d = filling - currentFilling
	d = clamp(sign(d), -abs(d), abs(d))
	currentFilling = clamp(currentFilling + d * delta * 2.0, 0.0, 1.0)
	
	var fillingMaxHeight = $Background/Filling.texture.get_height()
	var pixel = round(currentFilling * fillingMaxHeight)
	$Background/Filling.region_enabled = true
	$Background/Filling.region_rect.position.y = fillingMaxHeight - pixel
	$Background/Filling.region_rect.size.y = pixel
	$Background/Filling.offset.y = fillingMaxHeight - pixel
	
func setStage(stage:int):
	stage = clamp(int(stage), 1, 3)
	
	$Background.frame = int(stage) - 1
	$Background/Filling.texture = load("res://content/gadgets/shield/" + batteryTextureNamePrefix + str(stage) + ".png")
	$Background/Filling.region_rect.size = $Background/Filling.texture.get_size()
	$Overcharge.play(str(stage))
	
	match domeId:
		"dome1":
			match stage:
				1: $Background/Filling.position = Vector2(-3, 5)
				2: $Background/Filling.position = Vector2(-3, 2)
				3: $Background/Filling.position = Vector2(-4, -6)
		"dome2":
			match stage:
				1: $Background/Filling.position = Vector2(-1, -2)
				2: $Background/Filling.position = Vector2(-1, -9)
				3: $Background/Filling.position = Vector2(-1, -13)
		"dome3":
			match stage:
				1: $Background/Filling.position = Vector2(-2, 8)
				2: $Background/Filling.position = Vector2(-2, 4)
				3: $Background/Filling.position = Vector2(-3, -4)
		"dome4":
			match stage:
				1: $Background/Filling.position = Vector2(-1, -2)
				2: $Background/Filling.position = Vector2(-1, -9)
				3: $Background/Filling.position = Vector2(-1, -13)

func canFocusUse(keeper:Keeper) -> bool:
	return canOvercharge()

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	return tryOvercharge()

func overcharge():
	$OverchargeSound.play()
	Data.apply("shield.overcharged", true)
	Data.changeByInt("inventory.water", -1)
	Backend.event("gadget_overcharged", {"gadget": "shield"})

func canOvercharge() -> bool:
	return not Data.of("shield.overcharged") and Data.of("shield.overchargestrength") > 0

func remove():
	queue_free()
	Data.apply("shield.stage", 0)
