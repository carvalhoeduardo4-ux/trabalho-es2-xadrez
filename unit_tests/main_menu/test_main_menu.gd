extends GutTest

const MAIN_MENU_SCENE = preload("res://Scenes/MainMenu.tscn")

var menu
var play_button
var quit_button


func before_each():
	menu = MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	play_button = menu.get_node("CenterContainer/VBoxContainer/PlayButton")
	quit_button = menu.get_node("CenterContainer/VBoxContainer/QuitButton")


func after_each():
	menu.queue_free()
	await get_tree().process_frame


func test_menu_prepares_play_and_quit_buttons():
	assert_eq(play_button.text, "JOGAR")
	assert_eq(quit_button.text, "SAIR")
	assert_true(play_button.pressed.is_connected(
		Callable(menu, "_on_play_button_pressed")
	))
	assert_true(quit_button.pressed.is_connected(
		Callable(menu, "_on_quit_button_pressed")
	))


func test_play_button_changes_to_main_scene():
	menu._on_play_button_pressed()
	await get_tree().process_frame

	assert_eq(
		get_tree().current_scene.scene_file_path,
		"res://Scenes/main.tscn"
	)
