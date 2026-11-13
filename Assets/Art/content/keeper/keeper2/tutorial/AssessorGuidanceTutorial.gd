extends Tutorial

var bundlesActive := false

func _ready():
	super._ready()
	splitTutorialText("level.tutorial.assessor.bundleguide.desc2", "LabelDesc1", "LabelDesc2")
	listen("keeper2.bundleguide")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"keeper2.bundleguide":
			if newValue:
				bundlesActive = true

func process_trigger(delta:float) -> bool:
	if bundlesActive:
		return tutorialParent.carryables.size() >= 4
	else:
		return false

func process_confirm(delta:float):
	for bundle in get_tree().get_nodes_in_group("bundle"):
		if bundle.leaderNode == keeper:
			confirm()
