extends Drop

func _ready():
	super._ready()

func onCarried(p:Keeper):
	if Data.of("drillbot.buffguidance"):
		for driller in get_tree().get_nodes_in_group("drillbots"):
			driller.showNavigationArrow(self)

func onDropped(p:Keeper):
	if Data.of("drillbot.buffguidance"):
		for driller in get_tree().get_nodes_in_group("drillbots"):
			driller.hideNavigationArrow(self)
