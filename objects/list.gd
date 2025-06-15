class_name ConstellationList extends RichTextLabel

# TODO margins, CRITICAL can you actually edit these effectively?

const TEMPLATE = {
	"type": "list",
	"items": ["Lorem ipsum dolor sit amet consectetur adipiscing elit."]
}
const _type:String = "list"
var _items:Array:
	set(value):
		_items = value
		refresh_visuals()
var style:Style:
	set(value):
		style = value
		refresh_visuals()

func _prepare_text(t:String) -> String:
	var f:String = t
	f = f.insert(0, char(8226) + " ") # Bullet point

	# RichTextLabel uses bbcode for text alignment
	if style:
		if style.text_align == "center":
			f = f.insert(0, "[center]")
		elif style.text_align == "right":
			f = f.insert(0, "[right]")
	f = TextFormatting.replace(f, TextFormatting.TYPES.BOLD)
	f = TextFormatting.replace(f, TextFormatting.TYPES.ITALIC)

	return f

func _init(items:Array, style:Style = null) -> void:
	self.focus_mode = Control.FOCUS_CLICK

	self._items = items
	self.style = style

	self.fit_content = true
	self.bbcode_enabled = true
	self.scroll_active = false
	self.autowrap_mode = TextServer.AUTOWRAP_WORD
	self.context_menu_enabled = true ## TODO editing options in context like delete
	self.meta_underlined = false
	self.hint_underlined = false

	self.tooltip_text = "List"

#func _ready() -> void:
	#focus_entered.connect(_on_focus_entered)
	#focus_exited.connect(_on_focus_exited)

func refresh_visuals() -> void:
	text = ""
	var new_line:bool = false
	for item:String in _items:
		if new_line: newline()
		var entry:String = _prepare_text(item)
		append_text(entry)
		new_line = true


func to_dict() -> Dictionary:
	var data:Dictionary = TEMPLATE.duplicate()
	data["items"] = _items

	if style:
		var style_output = style.to_dict()
		if not style_output.is_empty():
			data.merge({"style": style_output})
	return data

func _to_string() -> String:
	return JSON.stringify(to_dict(), "\t", false)
