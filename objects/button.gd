class_name ConstellationButton extends Button

const TEMPLATE = {
	"type": "button",
	"label": "Lorem",
	"action": "."
}

const _type:String = "button"

var _label:String:
	set(value):
		_label = value
		refresh_visuals()
var _prelabel:String:
	set(value):
		_prelabel = value
		refresh_visuals()
var _action:String:
	set(value):
		_action = value
		refresh_visuals()
var style:Style:
	set(value):
		style = value
		refresh_visuals()

#func _prepare_text(t:String) -> String: ## Might not be needed here
	#var f:String = t
	#
	#f = TextFormatting.replace(f, TextFormatting.TYPES.BOLD)
	#f = TextFormatting.replace(f, TextFormatting.TYPES.ITALIC)
	#
	#return f

func _init(label:String, action:String = ".", style:Style = null) -> void:
	self._label = label
	self._action = action
	self.style = style
	
#func _ready() -> void:
	#focus_entered.connect(_on_focus_entered)
	#focus_exited.connect(_on_focus_exited)

func refresh_visuals() -> void:
	text = _label
	#othertext = _prelabel
	
func to_dict() -> Dictionary:
	var data:Dictionary = TEMPLATE.duplicate()
	data["label"] = _label
	data["action"] = _action
	
	if style:
		var style_output = style.to_dict()
		if not style_output.is_empty():
			data.merge({"style": style_output})
	return data

func _to_string() -> String:
	return JSON.stringify(to_dict(), "\t", false)
