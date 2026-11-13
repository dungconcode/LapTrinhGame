extends InputProcessor

var camera
var dragging := false
var rightDown := false
var dragStart

func becameLeaf():
	pass

func _process(delta):
	camera.position.x += Input.get_axis("ui_left", "ui_right") * camera.zoom.x / 400 * delta
	camera.position.y += Input.get_axis("ui_up", "ui_down") * camera.zoom.y / 400 * delta

func handle(event) -> bool:
	if desintegrating:
		return false
	
	if event is InputEventMouseButton:
		if Options.useGamepad:
			Options.setUseGamepad(false)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if left_click(event): return true
			else:
				if left_click_released(event): return true
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if wheel_up(event): return true
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if wheel_down(event): return true
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed():
				rightDown = true
				#right_click(event) #commented from first go at mouse controls
				return true
			else:
				rightDown = false
				if !dragging or event.position.distance_to(dragStart) < 5:
					return right_click(event)
				dragging = false
				return true
	elif event is InputEventMouseMotion:
		if rightDown and not dragging:
			dragging = true
			dragStart = event.position
			return drag_right(event)
		elif rightDown and dragging:
			return drag_right(event)
		else:
			return mouse_move(event)
	elif event is InputEventKey:
		return buttonEvent(event)
		
	return false

func right_click(event:InputEventMouseButton) -> bool:
	return false

func left_click(event:InputEventMouseButton) -> bool:
	return false

func left_click_released(event:InputEventMouseButton) -> bool:
	return false

func drag_right(event:InputEventMouseMotion) -> bool:
	var change = -event.relative / camera.zoom
	camera.position += change
	return true

func wheel_up(event:InputEventMouseButton) -> bool:
	changeZoom(1.1)
	return true

func wheel_down(event:InputEventMouseButton) -> bool:
	changeZoom(0.9)
	return true

func changeZoom(zoom_change:float):
	var viewport_size = get_viewport().size
	var previous_zoom = camera.zoom
	camera.zoom = camera.zoom * zoom_change
	var mouse_position = get_viewport().get_mouse_position()
	camera.offset += ((viewport_size * 0.5) - mouse_position) * (camera.zoom-previous_zoom)
