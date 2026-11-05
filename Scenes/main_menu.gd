extends Control

# Use @onready to grab references to the buttons once the scene loads
@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton

func _ready():
	# Connect the "pressed" signal of each button to its respective function
	play_button.pressed.connect(_on_play_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _on_play_button_pressed():
	# Replace the path below with the actual path to your main game scene
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_quit_button_pressed():
	# Closes the game application safely
	get_tree().quit()
