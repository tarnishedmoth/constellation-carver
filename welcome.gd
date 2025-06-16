class_name WelcomeScreen extends Control

signal ok_pressed

const FADE_IN_TIME:float = 2.3
const FADE_OUT_TIME:float = 0.7
const TRANSPARENT:Color = Color(Color.WHITE, 0.0)

@export var elements: Array[Control]
@export var element_fade_times: Array[float]
@export var typewriter:Array[Control]

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
		tween.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, ^"modulate", Color.WHITE, FADE_IN_TIME)
		var i:int = 0
		#var subtweens:Tween = create_tween()
		for element in elements:
			#var twee = element.create_tween()
			#twee.tween_property(element, ^"modulate", Color.WHITE, element_fade_times[i])
			#subtweens.tween_subtween(twee)
			element.modulate = TRANSPARENT
			tween.tween_property(element, ^"modulate", Color.WHITE, element_fade_times[i])
			tween.set_trans(Tween.TRANS_SINE)
			i+=1

		for element in typewriter:
			TypewriterEffect.apply_to(element, 0.07, 1.7)

		#tween.set_parallel()
		#tween.tween_subtween(subtweens)

func _on_welcome_ok_button_pressed() -> void:
	if tween: tween.kill()

	tween = create_tween()
	tween.tween_property(self, ^"modulate", TRANSPARENT, FADE_OUT_TIME)
	tween.tween_callback(hide)
	ok_pressed.emit()
