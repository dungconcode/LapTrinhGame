extends HudElement

const HEALTH_PER_PIXEL = 41
var potentialRepair:float

var repairTween:Tween
var repairTween2:Tween

func init():
	super.init()
	Data.listen(self, "dome.health")
	Data.listen(self, "dome.potentialrepair")
	Data.listen(self, "dome.maxhealth", true)
	$RepairRect.size.x = 0

func exit():
	Data.unlisten(self, "dome.health")
	Data.unlisten(self, "dome.potentialrepair")
	Data.unlisten(self, "dome.maxhealth")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"dome.maxhealth":
			if newValue < Data.of("dome.health"):
				updateRects(Data.of("dome.maxhealth"), Data.of("dome.potentialrepair"))
				Data.apply("dome.health", Data.of("dome.maxhealth"))
			else:
				updateRects(Data.of("dome.health"), Data.of("dome.potentialrepair"))
		"dome.health":
			if newValue < oldValue and newValue < Data.of("dome.maxhealth"):
				flash()
			if Data.of("dome.maxhealth") < newValue:
				Data.apply("dome.health", Data.of("dome.maxhealth"))
			updateRects(Data.of("dome.health"), Data.of("dome.potentialrepair"))
		"dome.potentialrepair":
			updateRects(Data.of("dome.health"), Data.of("dome.potentialrepair"))

func flash():
	#$FlashTween.seek($FlashTween.get_runtime())
	$FlashTween.interpolate_property(self, "modulate", Color(10,10,10,1), Color(1,1,1,1), 0.2, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$FlashTween.start()

func updateRects(newHealth, newRepair := 0.0):
	var mx = Data.of("dome.maxhealth")
	
	$BG/Segment.size.x = mx / HEALTH_PER_PIXEL
	$BG/Segment.position.x = $BG/Heart.size.x
	$BG/Terminus.position.x = $BG/Segment.position.x + $BG/Segment.size.x
	
	var barLength = $BG/Segment.size.x
	if mx > 0:
		$HealthRect.size.x = (barLength * (newHealth / float(mx)))
		var fraction = (newHealth + newRepair) / float(mx)
		$RepairRect.size.x = (barLength * min(1.0 , fraction))
		$BadRepairRect.size.x = (barLength * max(0.0 , fraction - 1.0))
		$BadRepairRect.position.x = $RepairRect.position.x + $RepairRect.size.x
	else:
		$HealthRect.size.x = 0
	
	if newRepair > 0.0:
		if repairTween == null:
			start_repair_tween()
	else:
		end_repair_tween()
		$RepairRect.modulate = Color.WHITE
		$BadRepairRect.modulate = Color.WHITE
	
	element_size.x = max(barLength/6 + 3, 6.5)
	emit_signal("request_rebuild")

const color_light_flash := Color(1.3,1.3,1.3)
const color_darken := Color(0.5,0.5,0.5)
const color_flash := Color(1.5,1.5,1.5)

func start_repair_tween():
	var tw = create_tween()
	tw.set_loops()
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): $RepairRect.modulate = Color.WHITE)
	tw.tween_property($RepairRect, "modulate", Color.WHITE * 1.3, 0.1).set_ease(Tween.EASE_OUT_IN)
	tw.tween_property($RepairRect, "modulate",Color.WHITE, 0.4).set_ease(Tween.EASE_IN_OUT)
	repairTween = tw
	
	tw = create_tween()
	tw.set_loops()
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property($BadRepairRect, "modulate", color_flash, 0.05).set_ease(Tween.EASE_OUT_IN)
	tw.tween_property($BadRepairRect, "modulate",  color_darken, 0.2).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property($BadRepairRect, "modulate",  color_flash, 0.05).set_ease(Tween.EASE_OUT_IN)
	tw.tween_property($BadRepairRect, "modulate",  color_darken, 0.2).set_ease(Tween.EASE_IN_OUT)
	repairTween2 = tw

func end_repair_tween():
	if repairTween != null:
		repairTween.kill()
		repairTween = null
	if repairTween2 != null:
		repairTween2.kill()
		repairTween2 = null
