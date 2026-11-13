extends Tutorial

var lastHealth

func _ready():
	super._ready()
	listen("dome.health")
	listen("inventory.floatingsand")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"dome.health":
			if not oldValue:
				lastHealth = newValue
				return
			if newValue > lastHealth:
				confirm()
			lastHealth = newValue
		"inventory.floatingsand":
			if newValue > 0:
				confirm()

func process_trigger(delta:float) -> bool:
	return lastHealth < 400 and Data.of("inventory.sand") == 0
