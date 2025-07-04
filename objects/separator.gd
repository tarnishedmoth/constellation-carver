class_name ConstellationSeparator extends Control

const TEMPLATE = {
	"type": "separator"
}
const _type:String = "separator"
func _init() -> void:
	# TODO figure out exactly how big this has to be
	self.custom_minimum_size = Vector2i(240, 12)
	self.focus_mode = Control.FOCUS_CLICK

	self.mouse_filter = Control.MOUSE_FILTER_STOP
	self.tooltip_text = "Separator"

func _draw() -> void:
	# TODO figure out exactly where this has to be
	draw_line(
		Vector2i(0, 6),
		Vector2i(400, 6),
		Color.BLACK
	)

func to_dict() -> Dictionary:
	return TEMPLATE.duplicate()

func _to_string() -> String:
	return JSON.stringify(to_dict(), "\t", false)
