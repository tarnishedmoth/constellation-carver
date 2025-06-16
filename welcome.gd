class_name WelcomeScreen extends Control

signal ok_pressed

const FADE_IN_TIME:float = 2.0
const FADE_OUT_TIME:float = 1.0
const TRANSPARENT:Color = Color(Color.WHITE, 0.0)

var tween:Tween

func _init() -> void:
	modulate = TRANSPARENT
	visible = false

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if tween: tween.kill()

	if visible:
		tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, ^"modulate", Color.WHITE, FADE_IN_TIME)

func _on_welcome_ok_button_pressed() -> void:
	if tween: tween.kill()

	tween = create_tween()
	tween.tween_property(self, ^"modulate", TRANSPARENT, FADE_OUT_TIME)
	tween.tween_callback(hide)
	ok_pressed.emit()
