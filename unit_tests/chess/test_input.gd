extends GutTest

const MAIN_SCENE = preload("res://Scenes/main.tscn")

var game
var chess


func before_each():
	game = MAIN_SCENE.instantiate()
	add_child(game)
	chess = game.get_node("Camera2D/board")
	chess.vs_ai = false


func after_each():
	game.free()


func _clear_board():
	chess.board.clear()
	for _row in range(8):
		chess.board.append([0, 0, 0, 0, 0, 0, 0, 0])


func _send_mouse_event_at_local_position(
	local_position: Vector2,
	button: int = MOUSE_BUTTON_LEFT,
	pressed: bool = true
):
	var viewport_position = chess.get_global_transform_with_canvas() * local_position
	var event = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = viewport_position
	if pressed:
		chess._input(event)


func _send_mouse_click_at_square(
	row: int,
	col: int,
	button: int = MOUSE_BUTTON_LEFT,
	pressed: bool = true
):
	var local_position = chess.board_to_local_position(row, col)
	await _send_mouse_event_at_local_position(local_position, button, pressed)


func test_click_cannot_select_piece_of_other_color():
	_clear_board()
	chess.board[1][3] = -1

	_send_mouse_click_at_square(1, 3)

	assert_false(chess.state)
	assert_false(chess.moves.has(Vector2(2, 3)))


func test_non_left_mouse_button_does_not_select_piece():
	_clear_board()
	chess.board[6][3] = 1

	_send_mouse_click_at_square(6, 3, MOUSE_BUTTON_RIGHT)

	assert_false(chess.state)
	assert_true(chess.moves.is_empty())


func test_click_during_promotion_does_not_change_selection_or_move():
	_clear_board()
	chess.board[6][3] = 1
	chess.promotion_square = Vector2(0, 3)

	_send_mouse_click_at_square(6, 3)

	assert_false(chess.state)
	assert_true(chess.selected_piece == Vector2.ZERO)
	assert_eq(chess.board[6][3], 1)
	assert_eq(chess.promotion_square, Vector2(0, 3))


func test_unpressed_mouse_event_does_not_select_piece():
	_clear_board()
	chess.board[6][3] = 1

	_send_mouse_click_at_square(6, 3, MOUSE_BUTTON_LEFT, false)

	assert_false(chess.state)
	assert_true(chess.moves.is_empty())


func test_click_outside_board_does_not_select_piece():
	_clear_board()
	chess.board[6][3] = 1

	_send_mouse_event_at_local_position(Vector2(73, 0))

	assert_false(chess.state)
	assert_true(chess.moves.is_empty())


func test_non_mouse_event_does_not_change_selection():
	_clear_board()
	chess.board[6][3] = 1

	chess._input(InputEventKey.new())

	assert_false(chess.state)
	assert_true(chess.moves.is_empty())
