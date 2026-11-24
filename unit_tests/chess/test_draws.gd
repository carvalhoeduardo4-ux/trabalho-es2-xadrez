extends GutTest

const MAIN_SCENE = preload("res://Scenes/main.tscn")

var game
var chess


func before_each():
	game = MAIN_SCENE.instantiate()
	add_child(game)
	chess = game.get_node("Camera2D/board")
	chess.vs_ai = false
	_clear_board()


func after_each():
	game.free()


func _clear_board():
	chess.board.clear()
	for _row in range(8):
		chess.board.append([0, 0, 0, 0, 0, 0, 0, 0])
	chess.fifty_move_rule = 0
	chess.unique_board_moves.clear()
	chess.amount_of_same.clear()
	chess.game_over = false
	chess.white = true


func test_insufficient_material_with_only_kings():
	chess.board[7][4] = 6
	chess.board[0][4] = -6
	assert_true(chess.insuficient_material())


func test_insufficient_material_with_one_king_and_one_bishop():
	chess.board[7][4] = 6
	chess.board[0][4] = -6
	chess.board[4][4] = 2
	assert_true(chess.insuficient_material())


func test_insufficient_material_with_two_knights_on_one_side():
	chess.board[7][4] = 6
	chess.board[0][4] = -6
	chess.board[3][3] = 2
	chess.board[3][4] = 2
	assert_false(chess.insuficient_material())


func test_threefold_position_detects_third_repetition():
	var position = [[6]]
	assert_false(chess.threefold_position(position))
	assert_false(chess.threefold_position(position))
	assert_true(chess.threefold_position(position))


func test_threefold_position_distinguishes_new_position():
	assert_false(chess.threefold_position([[6]]))
	assert_false(chess.threefold_position([[6], [1]]))
	assert_false(chess.threefold_position([[6], [2]]))


func test_check_game_state_sets_game_over_on_fifty_move_rule():
	chess.fifty_move_rule = 50
	chess.check_game_state()
	assert_true(chess.game_over)


func test_check_game_state_sets_game_over_on_insufficient_material():
	chess.board[7][4] = 6
	chess.board[0][4] = -6
	chess.check_game_state()
	assert_true(chess.game_over)


func test_check_game_state_reports_check():
	chess.board[7][4] = 6
	chess.board[7][0] = -4
	chess.check_game_state()
	assert_true(chess.is_in_check(true))
	assert_false(chess.game_over)


func test_check_game_state_reports_stalemate():
	chess.board[0][0] = -6
	chess.board[2][1] = 5
	chess.board[2][2] = 6
	chess.white = false
	chess.check_game_state()
	assert_true(chess.game_over)


func test_check_game_state_reports_checkmate_for_white():
	chess.board[7][0] = 6
	chess.board[0][7] = -6
	chess.board[6][1] = -5
	chess.board[6][0] = -4
	chess.white = true
	chess.check_game_state()
	assert_true(chess.game_over)
