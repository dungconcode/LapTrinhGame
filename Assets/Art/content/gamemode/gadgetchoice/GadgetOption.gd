extends TextureRect

signal selected

var id:String
var is_selected := false

var tween : Tween

func init(id:String):
	self.id = id
	$GadgetIcon.texture = Data.loadIconOrFallback("res://content/icons/" + id + ".png")
	if $GadgetIcon.texture:
		$GadgetIcon.custom_minimum_size = $GadgetIcon.texture.get_size() * 2
	$SelectedPanel.visible = false
	pivot_offset = size * 0.5
	scale = Vector2.ONE * 1.0
	
func _on_GadgetOption_focus_entered():
	$SelectedPanel.visible = true

func _on_GadgetOption_focus_exited():
	$SelectedPanel.visible = false

func _on_GadgetOption_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)\
	 	or InputMap.event_is_action(event, "ui_select") and event.pressed:
		emit_signal("selected")

func _process(delta):
	pass

func select():
	texture = preload("res://content/techtree/panels/big.png")
	pivot_offset = size * 0.5
	is_selected = true
	#defered because select is called before tween can be properly created
	call_deferred("tween_in")
	
func tween_in():
	kill_tween()
	tween = create_tween()
	if tween:
		tween.tween_property(self, "scale", scale * 1.05, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()
		tween.tween_property(self, "scale", Vector2.ONE / scale, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
func deselect():
	texture = preload("res://content/techtree/panels/big_dark.png")
	scale = Vector2.ONE
	is_selected = false
	kill_tween()
	tween = create_tween()
	if tween:
		tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

func _on_GadgetOption_mouse_entered():
	$SelectedPanel.visible = true

func _on_GadgetOption_mouse_exited():
	$SelectedPanel.visible = false

func kill_tween():
	if tween != null:
		tween.kill()
		tween = null
