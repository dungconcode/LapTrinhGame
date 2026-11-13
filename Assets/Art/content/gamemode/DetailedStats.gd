extends Control


func _ready() -> void:
	$ColorRect.color = Style.OVERLAY_COLOR_OUT
	Style.init(self)
	InputSystem.grabFocus(find_child("CancelButton"))
	
	if get_parent() == get_tree().root:
		for i in 2000:
			var id = Data.monsterIcons.keys().pick_random()
			var m = MonsterKillEvent.new(randi(), id)
			Recorder.monsterEvents.append(m)
		
		for id in Data.monsterIcons:
			GameWorld.trackedDamageReceived[id] = randi() % 20000
	
	var killCount := 0
	var monsters := []
	var monster_count := []
	for entry:MonsterKillEvent in Recorder.monsterEvents:
		var i = monsters.find(entry.monsterId)
		if i == -1:
			monsters.append(entry.monsterId)
			monster_count.append(1)
		else:
			monster_count[i] += 1
		killCount += 1
	
	for id in monsters:
		var c = getMonsterContainerWithLabel(id, str(monster_count[monsters.find(id)]))
		%MonstersKilledContainer.add_child(c)
	
	var damageReceivedCount := 0.0
	for id in GameWorld.trackedDamageReceived:
		var dmg = GameWorld.trackedDamageReceived[id]
		damageReceivedCount += dmg
		var c = getMonsterContainerWithLabel(id, str(round(dmg)))
		%MonsterDamageReceivedContainer.add_child(c)
	
	var damageDealtCount := 0.0
	for id in GameWorld.trackedDamageDealt:
		if ResourceLoader.exists("res://content/icons/" + id + ".png"):
			var box = VBoxContainer.new()
			box.size_flags_vertical = Control.SIZE_SHRINK_END
			var icon = TextureRect.new()
			icon.texture = load("res://content/icons/" + id + ".png")
			var iconSize:Vector2 = icon.texture.get_size()
			var frame = TextureRect.new()
			match int(iconSize.x):
				44:
					frame.texture = preload("res://content/techtree/panels/zero_dark.png")
				46:
					frame.texture = preload("res://content/techtree/panels/big_square_dark.png")
				72:
					frame.texture = preload("res://content/techtree/panels/big_dark.png")
				_:
					frame.texture = preload("res://content/techtree/panels/zero_bright.png")
			icon.custom_minimum_size = iconSize * 2
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			icon.position = (frame.texture.get_size() - icon.custom_minimum_size) * 0.5
			#if icon.custom_minimum_size.y < 100:
				## hack because here we mix bigger gadget icons with smaller upgrade icons. With the hack they look better aligned.
				## hack does not seem needed anymore now that we also add frames
				#box.add_theme_constant_override("separation", 40)
			frame.add_child(icon)
			box.add_child(frame)
			
			var dmg = GameWorld.trackedDamageDealt[id]
			damageDealtCount += dmg
			var label = Label.new()
			label.text = str(round(dmg))
			label.label_settings = preload("res://gui/fontsettings/NormalFontSettings.tres")
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(label)
			
			Style.init(box)
			
			%DamageDealtContainer.add_child(box)
	
	%KilledLabel.text = tr("level.gameover.stats.monsterskilled") + ": " + str(killCount)
	%DamageReceivedLabel.text = tr("level.gameover.stats.damagereceived") + ": " + str(round(damageReceivedCount))
	%DamageDealtLabel.text = tr("level.gameover.stats.damagedealt") + ": " + str(round(damageDealtCount))
	
	%PanelMonstersKilled.visible = Data.ofOr("postrun.showmonstercount", false)
	%PanelDamageReceived.visible = Data.ofOr("postrun.showdamagereceivedpermonster", false)
	%PanelDamageDealt.visible = Data.ofOr("postrun.showdamagedealttomonsters", false)

func getMonsterContainerWithLabel(id:String, txt:String):
	var label = Label.new()
	label.text = txt
	label.label_settings = preload("res://gui/fontsettings/NormalFontSettings.tres")
	label.set_anchors_preset(PRESET_CENTER_BOTTOM) 
	
	var outer := Control.new()
	if Data.monsterIcons.has(id.to_lower()):
		var sprite = AnimatedSprite2D.new()
		var data:Array = Data.monsterIcons.get(id.to_lower())
		sprite.sprite_frames = data[0]
		sprite.play(data[1])
		sprite.scale *= 2.0
		outer.custom_minimum_size = 2 * data[2] + Vector2(0, 0)
		var inner := Control.new()
		inner.set_anchors_preset(PRESET_CENTER) 
		outer.add_child(inner)
		inner.add_child(sprite)
		Style.init(sprite)
	else:
		outer.custom_minimum_size = Vector2(50, 50)
		label.text = id + ": " + label.text
	outer.add_child(label)
	
	return outer
