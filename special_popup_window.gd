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

enum TEXT_FORMAT {
	NONE = 0, # Text can be anything as long as it isn't empty.
	FILE = 1, # Text must not contain invalidating characters for a file name.
	PATH = 2, # Text can be a relative or absolute path format.
	REL_PATH = 3, # Text must be a relative path.
	ABS_PATH = 4, # Text must be an absolute path.
	WEB_PATH = 5, # Uses method in ParticleParser.
}

func popup_text_entry(details_text:String, heading:String = "Input Text", user_choice:bool = true, check_flag:TEXT_FORMAT = TEXT_FORMAT.NONE, populate_line_edit:String = "", callable:Callable = func(_choice:bool): pass) -> String:
	var text_entry_invalid:bool = true
	var attempted:bool = false

	line_edit.clear()
	if not populate_line_edit.is_empty():
		line_edit.text = populate_line_edit
	line_edit.show()

	while text_entry_invalid:
		var _details_text:String = details_text
		if attempted:
			_details_text += "\n\nText doesn't meet requirements, try again."

		var result = await popup(_details_text, heading, user_choice, callable)
		if result:

			var let:String = line_edit.text # Abbreviation
			if not let.is_empty():

				## Check Flags
				match check_flag:
					TEXT_FORMAT.FILE:
						if let.is_valid_filename(): break
					TEXT_FORMAT.PATH:
						if let.is_absolute_path() or let.is_relative_path(): break # TODO fix, relative path doesn't like leading slash
					TEXT_FORMAT.REL_PATH:
						if let.is_relative_path(): break # TODO fix, relative path doesn't like leading slash
					TEXT_FORMAT.ABS_PATH:
						if let.is_absolute_path(): break
					TEXT_FORMAT.WEB_PATH:
						if ParticleParser.is_valid_webpath(let): break
					_:
						break

					## If code continues here it is a fail to pass check flags.
			## Unreturnable value
			attempted = true
			continue
		else:
			# Cancel
			return ""

	line_edit.hide()
	return line_edit.text

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
