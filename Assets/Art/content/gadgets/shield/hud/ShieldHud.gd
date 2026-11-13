extends HudElement

var stage:int
var maxFilling:int
var shieldStrength:float
var overchargeStrength:float
var maxOverchargeStrength:float
var maxShieldStrength:float
var pxFromShieldStrength:float
var pxFromCharges:float

var maxAbilityDuration := 0.0

func init():
	super.init()
	Data.listen(self, "shield.remainingbattleuses", true)
	Data.listen(self, "shield.battleuses", true)
	Data.listen(self, "shield.stage", true)
	Data.listen(self, "shield.maxstrength", true)
	Data.listen(self, "shield.overchargestrength", true)
	Data.listen(self, "shield.strength", true)
	Data.listen(self, "shield.additionalstrength", true)
	Data.listen(self, "shield.remainingabilityduration", true)
	
	$Bar.visible = true
	$Bar/ShieldFilling.visible = true
	$Bar/LaststandOverlay.play()
	$Bar/OverchargeOverlay.play()

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"shield.remainingbattleuses":
			updateCharges(newValue)
		"shield.battleuses":
			updateSlots(newValue)
		"shield.stage":
			setStage(newValue)
		"shield.overchargestrength":
			maxOverchargeStrength = newValue
		"shield.additionalstrength":
			overchargeStrength = newValue
			$Bar/OverchargeOverlay.visible = newValue > 0.0
			updateFilling()
		"shield.strength":
			shieldStrength = newValue
			updateFilling()
		"shield.maxstrength":
			maxShieldStrength = newValue
			updateFilling()
		"shield.remainingabilityduration":
			$Bar/LaststandOverlay.visible = newValue > 0
			if oldValue:
				var fill = maxFilling * clamp(newValue / maxAbilityDuration, 0.0, 1.0)
				$Bar/AbilityDurationFilling.size.y = fill
			else:
				maxAbilityDuration = newValue
				$Bar/AbilityDurationFilling.size.y = 0

func updateFilling():
	var fill = maxFilling * (shieldStrength / maxShieldStrength)
	$Bar/ShieldFilling.size.y = fill
	
	if maxOverchargeStrength > 0.0:
		var ofill = maxFilling * (overchargeStrength / maxOverchargeStrength)
		$Bar/OverchargeFilling.size.y = ofill
	else:
		$Bar/OverchargeFilling.size.y = 0

func setStage(stage:int):
	self.stage = stage
	match int(self.stage):
		1: 
			$Bar.texture = preload("res://content/gadgets/shield/hud/bar1.png")
			maxFilling = 7
			pxFromShieldStrength = 18
		2: 
			$Bar.texture = preload("res://content/gadgets/shield/hud/bar2.png")
			maxFilling = 11
			pxFromShieldStrength = 22
		3: 
			$Bar.texture = preload("res://content/gadgets/shield/hud/bar3.png")
			maxFilling = 15
			pxFromShieldStrength = 26
		4: 
			$Bar.texture = preload("res://content/gadgets/shield/hud/bar4.png")
			maxFilling = 19
			pxFromShieldStrength = 30
	$Bar/ShieldFilling.position.y = 1 + maxFilling
	$Bar/OverchargeFilling.position.y = 1 + maxFilling
	$Bar/AbilityDurationFilling.position.y = 1 + maxFilling
	$Bar/OverchargeOverlay.position.y = 5.5 + maxFilling
	$Bar/LaststandOverlay.position.y = 5.5 + maxFilling
	
	var sy = (pxFromCharges + pxFromShieldStrength) / 6.0
	var rest = sy - floor(sy)
	if sy - floor(sy) < 0.2:
		sy = floor(sy)
		rest = 0
	else:
		sy = ceil(sy)
	element_size.y = sy
	
	$Bar.position.y = pxFromCharges + 1 + rest * 1.5 # =0.5 * 6
	
	emit_signal("request_rebuild")

func updateSlots(amount):
	for i in range(1, 4):
		get_node("Slot"+str(i)).visible = amount >= i
	match int(amount):
		1:
			pxFromCharges = 5
		2:
			pxFromCharges = 8
		3:
			pxFromCharges = 11
	
	setStage(stage)

func updateCharges(charges):
	for i in range(1, 4):
		find_child("Charge"+str(i)).visible = charges >= i
