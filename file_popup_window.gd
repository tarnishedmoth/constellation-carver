class_name FilePopupMenu extends PanelContainer

signal exited(confirmed:bool)

const FADE_TIME:float = 1.0

@export var text_box:CodeEdit
@export var confirm_button:Button
@export var cancel_button:Button

var modulate_tween:Tween

func popup_code(code:String = "", editable:bool = false) -> bool:
	text_box.text = code
	text_box.editable = editable
	text_box.get_v_scroll_bar().self_modulate = Utils.TRANSPARENT ## WORKING
	#text_box.get_v_scroll_bar().add_theme_stylebox_override("normal", StyleBoxEmpty.new()) # not working

	show()
	confirm_button.show()
	if editable:
		cancel_button.show()
		confirm_button.text = "Confirm"
	else:
		cancel_button.hide()
		confirm_button.text = "OK"

	var result:bool = await exited
	hide()
	return result

func _on_visibility_changed() -> void:
	if visible:
		if modulate_tween:
			modulate_tween.kill()
		modulate_tween = create_tween()
		modulate_tween.tween_property(self, ^"modulate", Color.WHITE, FADE_TIME).from(Utils.TRANSPARENT)
	else:
		text_box.clear()

func _on_cancel_button_pressed() -> void:
	exited.emit(false)

func _on_confirm_button_pressed() -> void:
	exited.emit(true)
