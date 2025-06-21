class_name SFXInterface extends Node

@onready var click1: AudioStreamPlayer = $Click1
@onready var click2: AudioStreamPlayer = $Click2
@onready var switch: AudioStreamPlayer = $Switch
@onready var click_3: AudioStreamPlayer = $Click3

func play(sound:AudioStreamPlayer) -> void:
	sound.play()
