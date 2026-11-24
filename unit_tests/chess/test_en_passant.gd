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
	chess.en_passant = Vector2(-1, -1)
	chess.white = true


func test_white_pawn_moves_en_passant_to_the_right():
	chess.board[3][4] = 1
	chess.en_passant = Vector2(1, 5)
	chess.selected_piece = Vector2(3, 4)
	assert_true(chess.get_pawn_moves().has(Vector2(2, 5)))


func test_white_pawn_moves_en_passant_to_the_left():
	chess.board[3][4] = 1
	chess.en_passant = Vector2(1, 3)
	chess.selected_piece = Vector2(3, 4)
	assert_true(chess.get_pawn_moves().has(Vector2(2, 3)))


func test_black_pawn_moves_en_passant_to_the_right():
	chess.white = false
	chess.board[4][4] = -1
	chess.en_passant = Vector2(6, 5)
	chess.selected_piece = Vector2(4, 4)
	assert_true(chess.get_pawn_moves().has(Vector2(5, 5)))


func test_black_pawn_moves_en_passant_to_the_left():
	chess.white = false
	chess.board[4][4] = -1
	chess.en_passant = Vector2(6, 3)
	chess.selected_piece = Vector2(4, 4)
	assert_true(chess.get_pawn_moves().has(Vector2(5, 3)))


func test_set_move_removes_captured_pawn_by_en_passant():
	chess.board[3][4] = 1
	chess.board[3][5] = -1
	chess.en_passant = Vector2(1, 5)
	chess.selected_piece = Vector2(3, 4)
	chess.moves = [Vector2(2, 5)]
	chess.set_move(2, 5)
	assert_eq(chess.board[3][5], 0)
	assert_eq(chess.board[2][5], 1)


func test_make_simulated_move_restores_en_passant_capture():
	chess.board[3][4] = 1
	chess.board[3][5] = -1
	chess.en_passant = Vector2(3, 5)
	var backup = chess.make_simulated_move(Vector2(3, 4), Vector2(2, 5))
	assert_eq(chess.board[3][5], 0)
	chess.undo_simulated_move(backup)
	assert_eq(chess.board[3][4], 1)
	assert_eq(chess.board[3][5], -1)
	assert_eq(chess.board[2][5], 0)
