extends Container

signal selected

var id:String
var disabled := false
var titleText:String
var starting_position = null
var is_selected = false

func _ready():
	Style.init(self)

	$Back.hide()
	
	await get_tree().create_timer(0.1).timeout
	pivot_offset = size/2
	starting_position = position

func _process(_delta):
	if starting_position != null:
		if is_selected:
			position.y = starting_position.y + sin(Time.get_ticks_msec()/200.0) * 4
			var c = sin(Time.get_ticks_msec()/400.0) * 0.15 + 1.15
			modulate = Color(1,1,c,1) * c
		else:
			position = starting_position
			modulate = Color(1,1,1,1)
	
func init(id:String):
	self.id = id
	var icon:String
	var titleKey:String
	var descKey:String
	var type:String
	match id:
		"dome2": 
			icon = "loadout_dome2"
			titleKey = "upgrades.dome2.title"
			descKey = "upgrades.dome2.desc"
			type = "level.gameover.unlock.dome"
		"dome3": 
			icon = "loadout_dome3"
			titleKey = "upgrades.dome3.title"
			descKey = "upgrades.dome3.desc"
			type = "level.gameover.unlock.dome"
		"dome4": 
			icon = "loadout_dome4"
			titleKey = "upgrades.dome4.title"
			descKey = "upgrades.dome4.desc"
			type = "level.gameover.unlock.dome"
		"keeper2": 
			icon = "loadout_keeper2"
			titleKey = "upgrades.keeper2.title"
			descKey = "upgrades.keeper2.desc"
			type = "level.gameover.unlock.keeper"
		"shield-battle2": 
			icon = "loadout_shield"
			titleKey = "upgrades.shieldbattlereflect.title"
			descKey = "upgrades.shieldbattlereflect.desc"
			type = "level.gameover.unlock.gadgetability"
		"shield-battle3": 
			icon = "loadout_shield"
			titleKey = "upgrades.shieldbattleinvulnerable.title"
			descKey = "upgrades.shieldbattleinvulnerable.desc"
			type = "level.gameover.unlock.gadgetability"
		"repellent": 
			icon = "loadout_repellent"
			titleKey = "upgrades.repellent.title"
			descKey = "upgrades.repellent.desc"
			type = "level.gameover.unlock.gadget"
		"repellent-battle2": 
			icon = "loadout_repellent"
			titleKey = "upgrades.repellentbattlehealthreduction.title"
			descKey = "upgrades.repellentbattlehealthreduction.desc"
			type = "level.gameover.unlock.gadgetability"
		"repellent-battle3": 
			icon = "loadout_repellent"
			titleKey = "upgrades.repellentbattleslowdownstun1.title"
			descKey = "upgrades.repellentbattleslowdownstun2.title"
			type = "level.gameover.unlock.gadgetability"
		"orchard": 
			icon = "loadout_orchard"
			titleKey = "upgrades.orchard.title"
			descKey = "upgrades.orchard.desc"
			type = "level.gameover.unlock.gadget"
		"orchard-battle2": 
			icon = "loadout_orchard"
			titleKey = "upgrades.orchardbattleshield.title"
			descKey = "upgrades.orchardbattleshield.desc"
			type = "level.gameover.unlock.gadgetability"
		"droneyard": 
			icon = "loadout_droneyard"
			titleKey = "upgrades.droneyard.title"
			descKey = "upgrades.droneyard.desc"
			type = "level.gameover.unlock.gadget"
		"droneyard-battle2": 
			icon = "loadout_droneyard"
			titleKey = "upgrades.droneyardparasites.title"
			descKey = "upgrades.droneyardparasites.desc"
			type = "level.gameover.unlock.gadgetability"
		"droneyard-battle3": 
			icon = "loadout_droneyard"
			titleKey = "upgrades.droneyardbattlegridquick1.title"
			descKey = "upgrades.droneyardbattlegridquick1.desc"
			type = "level.gameover.unlock.gadgetability"
		CONST.MODE_PRESTIGE: 
			icon = "loadout_prestige"
			titleKey = "upgrades.prestige.title"
			descKey = "upgrades.prestige.desc"
			type = "level.gameover.unlock.gamemode"
		CONST.MODE_PRESTIGE_ENDLESS: 
			icon = "loadout_prestige"
			titleKey = "loadout.prestige.endless"
			descKey = "loadout.prestige.endless.description"
			type = "level.gameover.unlock.gamemodevariant"
		CONST.MODE_PRESTIGE_MINER: 
			icon = "loadout_prestige"
			titleKey = "loadout.prestige.miner"
			descKey = "loadout.prestige.miner.description"
			type = "level.gameover.unlock.gamemodevariant"
		CONST.MODE_PRESTIGE_PROVOCATION: 
			icon = "loadout_prestige"
			titleKey = "loadout.prestige.provocation"
			descKey = "loadout.prestige.provocation.description"
			type = "level.gameover.unlock.gamemodevariant"
		CONST.MODE_ASSIGNMENTS: 
			icon = "loadout_assignments"
			titleKey = "upgrades.assignments.title"
			descKey = "upgrades.assignments.desc"
			type = "level.gameover.unlock.gamemode"
			
	find_child("IconRect").texture = Data.loadIconOrFallback("res://content/icons/"+icon+".png")
	titleText = tr(titleKey)
	find_child("TitleLabel").text = titleText
	find_child("TypeTitleLabel").text = tr(type)
	find_child("DescriptionLabel").text = tr(descKey)
	
func _on_LoadoutOption_focus_entered():
	if not disabled:
		set('theme_override_styles/panel', preload("res://gui/buttons/button_pressed.tres"))

func _on_LoadoutOption_focus_exited():
	if not is_selected:
		set('theme_override_styles/panel', preload("res://gui/buttons/button_normal.tres"))

func _on_LoadoutOption_gui_input(event):
	if disabled:
		return
	
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)\
	or (InputMap.event_is_action(event, "ui_select") and event.pressed):
		emit_signal("selected")
		Audio.sound("gui_select")
		pressed()

func _on_LoadoutOption_mouse_entered():
	if not disabled:
		set('theme_override_styles/panel', preload("res://gui/buttons/button_hover.tres"))

func _on_LoadoutOption_mouse_exited():
	find_child("TitleLabel").set('theme_override_colors/font_color', null)
	if not is_selected:
		set('theme_override_styles/panel', preload("res://gui/buttons/button_normal.tres"))

func pressed():
	if disabled:
		return
	
	if has_focus():
		is_selected = true
		$Tween.interpolate_property(self, "scale", Vector2(1,1), Vector2(0, 1), 0.1, Tween.TRANS_SINE, Tween.EASE_OUT)
		$Tween.interpolate_property(self, "scale", Vector2(0,1), Vector2(1, 1), 0.1, Tween.TRANS_SINE, Tween.EASE_OUT, 0.1)
		$Tween.interpolate_property(self, "scale", Vector2(1,1), Vector2(1.05, 1.05), 0.2, Tween.TRANS_SINE, Tween.EASE_OUT, 0.2)
		$Tween.interpolate_property(self, "scale", Vector2(1.05,1.05), Vector2(1.0, 1.0), 0.2, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.4)
		$Tween.start()
		await get_tree().create_timer(0.2).timeout
		grab_focus()
		set('theme_override_styles/panel', preload("res://gui/buttons/button_pressed.tres"))

func releasePressed():
	is_selected = false
	set('theme_override_styles/panel', preload("res://gui/buttons/button_normal.tres"))

func highlight():
	$Tween.interpolate_property(self, "scale", Vector2(1,1), Vector2(1.05, 1.05), 0.3, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()

func reject():
	$Back.show()
	$Tween.interpolate_property(self, "scale", Vector2(1,1), Vector2(0, 1), 0.1, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "scale", Vector2(0,1), Vector2(1, 1), 0.1, Tween.TRANS_SINE, Tween.EASE_OUT, 0.1)
	$Tween.start()
