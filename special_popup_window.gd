class_name SpecialPopupWindow extends PanelContainer

signal exited(confirmed:bool)

@export var header:Label
@export var line_edit:LineEdit
@export var details:Label
@export var confirm_button:Button
@export var ok_button:Button
@export var cancel_button:Button
@export var main:MainScreen

var call_on_complete:Callable

func _ready() -> void: hide()

func popup_text_entry(details_text:String, heading:String = "Warning", user_choice:bool = false, callable:Callable = func(_choice:bool): pass) -> String:
	line_edit.clear()
	line_edit.show()
	await get_tree().process_frame

	var result = await popup(details_text, heading, user_choice, callable)
	if result:
		line_edit.hide()
		return line_edit.text
	else:
		line_edit.hide()
		return ""

func popup(details_text:String, heading:String = "Warning", user_choice:bool = false, callable:Callable = func(_choice:bool): pass) -> bool:
	header.text = heading
	details.text = details_text
	call_on_complete = callable

	ok_button.visible = !user_choice
	confirm_button.visible = user_choice
	cancel_button.visible = user_choice

	show()

	return await exited

func _on_confirm_pressed() -> void:
	if call_on_complete.is_valid():
		call_on_complete.call(true)
	hide()
	exited.emit(true)

func _on_cancel_pressed() -> void:
	if call_on_complete.is_valid():
		call_on_complete.call(false)
	hide()
	exited.emit(false)
