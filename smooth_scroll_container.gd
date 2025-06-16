class_name SmoothScrollContainer extends ScrollContainer

var scroll_speed: float = 480.0 ## pixels per second
var tween: Tween

var moving_position:float:
	set(value):
		set_deferred(&"scroll_vertical", value)

func smooth_scroll(from_top:float) -> void:
	if tween:
		tween.kill()

	var target:float = maxf(from_top, 0.0)
	var distance:float = absf(scroll_vertical - from_top)
	var duration:float = sqrt(distance/scroll_speed)

	tween = create_tween()
	if distance > 300.0:
		tween.set_trans(Tween.TRANS_BOUNCE)
		tween.set_ease(Tween.EASE_OUT)
		duration *= 1.5
	else:
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, ^"moving_position", from_top, duration).from(scroll_vertical)
