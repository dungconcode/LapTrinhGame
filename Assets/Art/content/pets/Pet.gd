extends Node2D

@export var id := ""
@export var looksLeft := false
@export var randomAction := true
@export var sleepingPositions := []
@export var emotePositionByAnimationPos := {}
@export var zIndexByDome := {}
@export var offsetXWhenFlipped := 0

var positions
var supportedPositions := []
var currentPos:String
var currentActions := []
var currentActionIndex:int
var currentlyPlayingAudioNode
var unflippedEmoteX:int
var defaultEmotePos:Vector2
var defaultZIndex:int

var switchCooldown := 0.0

func _ready():
	Style.init(self)
	
	unflippedEmoteX = $EmoteSprite.position.x
	
	var scenePath = "res://content/pets/" + id + "/Positions" + Data.startCaptialized(Level.domeId()) + ".tscn"
	var scene = load(scenePath)
	if scene:
		positions = scene.instantiate()
		Level.dome.add_child(positions)
	else:
		Logger.error("pet positions missing", "Pet.ready", scenePath)
		queue_free()
		return
	
	var animatedSprite: AnimatedSprite2D = $Sprite2D as AnimatedSprite2D
	animatedSprite.animation_looped.connect(_on_sprite2d_looped)
	
	for a in $Sprite2D.sprite_frames.get_animation_names():
		if a.find("idle") != -1:
			var posId = a.substr(3, a.find("_") - 3)
			supportedPositions.append("pos"+posId)
	
	var emote = find_child("EmoteSprite")
	if emote:
		emote.visible = false
		defaultEmotePos = emote.position
		var greeting = find_child("GreetingSound")
		if greeting:
			greeting.connect("finished", Callable(emote, "hide"))
	
	defaultZIndex = z_index
	
	findRandomPlace()
	
	add_to_group("lostL")
	add_to_group("saveable")
	
	Data.listen(self, "event.keepers.insidedome")

func propertyChanged(property:String, oldValue, newValue):
	if newValue and not oldValue and not sleepingPositions.has(currentPos):
		emote()

func emote():
	var greeting = find_child("GreetingSound")
	if greeting:
		greeting.play()
	
	var emote = find_child("EmoteSprite")
	if emote:
		emote.visible = true
		if emotePositionByAnimationPos.has(currentPos):
			emote.position = emotePositionByAnimationPos[currentPos]
		else:
			emote.position = defaultEmotePos

func serialize()->Dictionary:
	var data = {}
	data["meta.priority"] = 100
	data["meta.kind"] = "generic"
	return data

func deserialize(data: Dictionary):
	findRandomPlace()

func _process(delta):
	if GameWorld.devMode and Input.is_action_just_pressed("f4"):
		findRandomPlace()
	if GameWorld.devMode and Input.is_action_just_pressed("f2"):
		cycleAllPlaces()
	if switchCooldown > 0.0:
		switchCooldown -= delta
	else:
		for keeper in Keepers.getAll():
			if keeper.global_position.y < 200.0:
				return
		findRandomPlace()

func findRandomPlace():
	var consideredPositions := []
	for place in positions.get_children():
		var pos = getPosPrefix(place)
		if supportedPositions.has(pos):
			consideredPositions.append(place)
	
	if consideredPositions.size() > 1 and consideredPositions.has(currentPos):
		consideredPositions.erase(currentPos)
	
	if consideredPositions.is_empty():
		visible = false
		return
	
	var place = consideredPositions[randi() % consideredPositions.size()]
	currentPos = getPosPrefix(place)
	if place.name.ends_with("left"):
		$Sprite2D.flip_h = not looksLeft
	elif place.name.ends_with("right"):
		$Sprite2D.flip_h = looksLeft
	else:
		$Sprite2D.flip_h = randf() > 0.5
	
	
	if $Sprite2D.flip_h:
		$Sprite2D.offset.x = offsetXWhenFlipped
		$EmoteSprite.position.x = -unflippedEmoteX
	else:
		$Sprite2D.offset.x = 0
		$EmoteSprite.position.x = unflippedEmoteX
	
	startAnimation(currentPos + "_idle")
	currentActions.clear()
	currentActionIndex = 0
	for a in $Sprite2D.sprite_frames.get_animation_names():
		if a.begins_with(currentPos) and a.find("action") != -1:
			currentActions.append(a)
	
	position = place.position
	
	visible = true
	switchCooldown = 30.0
	
	z_index = zIndexByDome.get(Level.domeId(), {}).get(currentPos, defaultZIndex)

func getPosPrefix(place):
	var positionIndex = place.name.split("_")[0]
	var idx = positionIndex.split("n")[1]
	return str("pos", idx)

func cycleAllPlaces():
	var consideredPositions := []
	for place in positions.get_children():
		var pos = getPosPrefix(place)
		if supportedPositions.has(pos):
			consideredPositions.append(place)
	
	
	for i in consideredPositions.size():
		var place = consideredPositions[i]
		currentPos = getPosPrefix(place)
		if place.name.ends_with("left"):
			$Sprite2D.flip_h = not looksLeft
		elif place.name.ends_with("right"):
			$Sprite2D.flip_h = looksLeft
		else:
			$Sprite2D.flip_h = randf() > 0.5
		
		
		startAnimation(currentPos + "_idle")
		position = place.position
		visible = true
		switchCooldown = 30.0
		var t = Timer.new()
		add_child(t)
		t.wait_time = 2.0
		t.start()
		t.connect("timeout", Callable(t, "queue_free"))
		await t.timeout


func startAnimation(id:String):
	$Sprite2D.play(id)
	var audioId = id.capitalize().replace(" ", "")
	if currentlyPlayingAudioNode:
		currentlyPlayingAudioNode.stop()
		currentlyPlayingAudioNode = null
	
	if has_node(audioId):
		var node = get_node(audioId)
		node.play()
		currentlyPlayingAudioNode = node

func _on_sprite2d_looped() -> void:
	sprite2dAnimationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	sprite2dAnimationFinishedCheck()

func sprite2dAnimationFinishedCheck() -> void:
	if not visible:
		return
	
	if $Sprite2D.animation == currentPos + "_idle" and currentActions.size() > 0:
		if randf() > 0.5:
			if randomAction:
				currentActionIndex = randi() % currentActions.size()
				startAnimation(currentActions[currentActionIndex])
			else:
				currentActionIndex = 0
				startAnimation(currentActions[currentActionIndex])
	elif randomAction or currentActionIndex >= currentActions.size() - 1:
		startAnimation(currentPos + "_idle")
	else:
		# play consecutive action
		currentActionIndex += 1
		startAnimation(currentActions[currentActionIndex])

func onGameLost():
	visible = false

func greetingSoundFinished():
	var emote = find_child("EmoteSprite")
	if emote:
		emote.visible = false

#### handy documentation for everything the pets do and how position nodes need to be formatted

# posN_idle is in what type of location the pet can be (e.g. all pos1_actions suppose the pet is in the air)
#
# posN_idle is required for there to be posN_actionM
# not every position needs an action but every action needs a respective idle anim
#
# PositionN_M_right
# N = pos
# M = count
# _right= optional suffix that forces direction, can also be _left
##
# 1 - cat
#	pos1 sitting
#	pos2 lying (force direction)
#	pos3 lying, turned away
#	pos4 scratching (force direction)
# 2 - penguin
#	pos1 sitting upright, looking down, perched
#	pos2 lying face down
#	pos3 leaning forward, side view (force direction, use for mine hole)
#	pos4 lying on back
#	pos5 side view rocking back and forth
# 3 - bat
#	pos1 sitting upright, facing forward
#	pos2 hovering
#	pos3 resting, sitting, wings down
#	pos4 watchful side view (force direction most of the time)
# 4 - skull
#	pos1 hovering mid-air (force direction most of the time)
#	pos2 hovering slightly above ground (always left?)
#	# note: is oriented left most of the time because skull isn't centered. it's to the left of each frame because some actions need the space to the right
# 5 - floating sea horse
#	pos1 floating
# 6 - armadillo
#	pos1 sitting, scheming
#	pos2 bouncing on floor
#	pos3 wormhole
#	pos4 lying around
#	pos5 lying around (can teleport)
#	# note: center is above the head bc teleport anim
