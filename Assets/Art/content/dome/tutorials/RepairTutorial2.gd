extends Tutorial

var lastHealth

func _ready():
	super._ready()
	listen("dome.health")

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

func process_trigger(delta:float) -> bool:
	return lastHealth < 400 and Data.of("inventory.sand") > 0
