class_name FilePopupMenu extends PanelContainer

signal exited(confirmed:bool)
signal selected_filepath(filepath:String)

const FADE_TIME:float = 1.0

@export var code_box:CodeEdit
@export var confirm_button:Button
@export var cancel_button:Button

@onready var open_image_file_dialog: FileDialog = %OpenImageFileDialog

var modulate_tween:Tween

func _ready() -> void:
	hide()

func popup_code(code:String = "", editable:bool = false) -> bool:
	code_box.show()
	code_box.text = code
	code_box.editable = editable
	code_box.get_v_scroll_bar().self_modulate = Utils.TRANSPARENT ## WORKING
	#code_box.get_v_scroll_bar().add_theme_stylebox_override("normal", StyleBoxEmpty.new()) # not working

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

func popup_image_file_picker() -> String: ## Filepath
	open_image_file_dialog.popup()
	var _filepath:String = await selected_filepath
	return _filepath


func _on_visibility_changed() -> void:
	if visible:
		if modulate_tween:
			modulate_tween.kill()
		modulate_tween = create_tween()
		modulate_tween.tween_property(self, ^"modulate", Color.WHITE, FADE_TIME).from(Utils.TRANSPARENT)

func _on_cancel_button_pressed() -> void:
	exited.emit(false)

func _on_confirm_button_pressed() -> void:
	exited.emit(true)


func _on_open_image_file_dialog_file_selected(path: String) -> void:
	selected_filepath.emit(path)

func _on_open_image_file_dialog_canceled() -> void:
	selected_filepath.emit("")
