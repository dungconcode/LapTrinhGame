extends Label

@export var action:String # (String, "pickup", "drop")

func _ready():
	var ip = InputSystem.getLastChild()
	var keeper = Keepers.getKeeperOfDeviceId(ip.deviceId)
	if keeper:
		match action:
			"pickup":
				match keeper.techId:
					"keeper1": 
						text = tr("options.keybindings.action.keeper.pickup")
					"keeper2": 
						text = tr("options.keybindings.action.keeper.gravitycollect")
			"drop":
				match keeper.techId:
					"keeper1": 
						text = tr("options.keybindings.action.keeper.drop")
					"keeper2": 
						text = tr("options.keybindings.action.keeper.gravityball")
