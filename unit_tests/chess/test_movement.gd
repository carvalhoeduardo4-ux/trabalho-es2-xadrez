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


func _get_moves_for(piece: int, row: int, col: int, is_white: bool = true):
	chess.white = is_white
	chess.board[row][col] = piece
	chess.selected_piece = Vector2(row, col)
	return chess.get_moves()


func test_initial_board_has_standard_piece_layout():
	var expected = [
		[-4, -2, -3, -5, -6, -3, -2, -4],
		[-1, -1, -1, -1, -1, -1, -1, -1],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[1, 1, 1, 1, 1, 1, 1, 1],
		[4, 2, 3, 5, 6, 3, 2, 4]
	]

	assert_eq(chess.board, expected)


func test_rook_moves_along_ranks_and_files():
	_clear_board()

	var moves = _get_moves_for(4, 4, 3)

	assert_eq(moves.size(), 14)
	assert_true(moves.has(Vector2(4, 0)))
	assert_true(moves.has(Vector2(4, 7)))
	assert_true(moves.has(Vector2(0, 3)))
	assert_true(moves.has(Vector2(7, 3)))
	assert_false(moves.has(Vector2(3, 2)))


func test_bishop_moves_diagonally():
	_clear_board()

	var moves = _get_moves_for(3, 3, 3)

	assert_eq(moves.size(), 13)
	assert_true(moves.has(Vector2(0, 0)))
	assert_true(moves.has(Vector2(0, 6)))
	assert_true(moves.has(Vector2(6, 0)))
	assert_true(moves.has(Vector2(7, 7)))
	assert_false(moves.has(Vector2(3, 4)))


func test_queen_moves_orthogonally_and_diagonally():
	_clear_board()

	var moves = _get_moves_for(5, 3, 3)

	assert_eq(moves.size(), 27)
	assert_true(moves.has(Vector2(3, 7)))
	assert_true(moves.has(Vector2(0, 3)))
	assert_true(moves.has(Vector2(0, 0)))
	assert_true(moves.has(Vector2(7, 7)))


func test_queen_stops_at_friendly_piece_and_captures_enemy_piece():
	_clear_board()
	chess.board[3][4] = 1
	chess.board[5][3] = -5

	var moves = _get_moves_for(5, 3, 3)

	assert_true(moves.has(Vector2(3, 2)))
	assert_false(moves.has(Vector2(3, 4)))
	assert_false(moves.has(Vector2(3, 5)))
	assert_true(moves.has(Vector2(5, 3)))
	assert_false(moves.has(Vector2(6, 3)))
	assert_false(moves.has(Vector2(7, 3)))


func test_king_moves_one_square_from_center_or_corner():
	_clear_board()
	var center_moves = _get_moves_for(6, 3, 3)
	assert_eq(center_moves.size(), 8)

	_clear_board()
	var corner_moves = _get_moves_for(6, 0, 0)
	assert_eq(corner_moves.size(), 3)
	assert_true(corner_moves.has(Vector2(0, 1)))
	assert_true(corner_moves.has(Vector2(1, 0)))
	assert_true(corner_moves.has(Vector2(1, 1)))


func test_knight_moves_in_l_shape_and_can_jump_over_pieces():
	_clear_board()
	chess.board[3][3] = 1
	chess.board[4][3] = -1

	var moves = _get_moves_for(2, 4, 4)

	assert_eq(moves.size(), 8)
	assert_true(moves.has(Vector2(2, 3)))
	assert_true(moves.has(Vector2(3, 2)))

	_clear_board()
	var corner_moves = _get_moves_for(2, 0, 0)
	assert_eq(corner_moves.size(), 2)
	assert_true(corner_moves.has(Vector2(1, 2)))
	assert_true(corner_moves.has(Vector2(2, 1)))


func test_rook_can_capture_enemy_and_stops_at_friendly_piece():
	_clear_board()
	chess.board[4][5] = 1
	chess.board[2][3] = -1

	var moves = _get_moves_for(4, 4, 3)

	assert_eq(moves.size(), 9)
	assert_true(moves.has(Vector2(2, 3)))
	assert_true(moves.has(Vector2(4, 4)))
	assert_false(moves.has(Vector2(1, 3)))
	assert_false(moves.has(Vector2(4, 5)))
	assert_false(moves.has(Vector2(4, 6)))


func test_bishop_stops_at_friendly_piece_and_can_capture_enemy():
	_clear_board()
	chess.board[1][1] = 1
	chess.board[5][5] = -3

	var moves = _get_moves_for(3, 3, 3)

	assert_true(moves.has(Vector2(2, 2)))
	assert_false(moves.has(Vector2(1, 1)))
	assert_false(moves.has(Vector2(0, 0)))
	assert_true(moves.has(Vector2(4, 4)))
	assert_true(moves.has(Vector2(5, 5)))
	assert_false(moves.has(Vector2(6, 6)))


func test_king_and_knight_can_capture_enemy_but_not_move_onto_friendly_piece():
	_clear_board()
	chess.board[2][3] = 1
	chess.board[2][4] = -1
	var king_moves = _get_moves_for(6, 3, 3)
	assert_false(king_moves.has(Vector2(2, 3)))
	assert_true(king_moves.has(Vector2(2, 4)))

	_clear_board()
	chess.board[2][3] = 1
	chess.board[2][5] = -1
	var knight_moves = _get_moves_for(2, 4, 4)
	assert_false(knight_moves.has(Vector2(2, 3)))
	assert_true(knight_moves.has(Vector2(2, 5)))


func test_white_and_black_pawns_can_advance_one_or_two_squares_from_start():
	_clear_board()
	var white_moves = _get_moves_for(1, 6, 4)
	assert_eq(white_moves.size(), 2)
	assert_true(white_moves.has(Vector2(5, 4)))
	assert_true(white_moves.has(Vector2(4, 4)))

	_clear_board()
	var black_moves = _get_moves_for(-1, 1, 4, false)
	assert_eq(black_moves.size(), 2)
	assert_true(black_moves.has(Vector2(2, 4)))
	assert_true(black_moves.has(Vector2(3, 4)))


func test_pawns_cannot_advance_through_blocking_pieces():
	_clear_board()
	chess.board[5][4] = -4
	var white_moves = _get_moves_for(1, 6, 4)
	assert_true(white_moves.is_empty())

	_clear_board()
	chess.board[2][4] = 4
	var black_moves = _get_moves_for(-1, 1, 4, false)
	assert_true(black_moves.is_empty())

	_clear_board()
	chess.board[4][4] = -4
	white_moves = _get_moves_for(1, 6, 4)
	assert_eq(white_moves, [Vector2(5, 4)])

	_clear_board()
	chess.board[3][4] = 4
	black_moves = _get_moves_for(-1, 1, 4, false)
	assert_eq(black_moves, [Vector2(2, 4)])


func test_pawns_only_capture_enemy_pieces_diagonally():
	_clear_board()
	chess.board[2][2] = -1
	chess.board[2][4] = -3
	chess.board[2][3] = -4
	var white_moves = _get_moves_for(1, 3, 3)
	assert_eq(white_moves.size(), 2)
	assert_true(white_moves.has(Vector2(2, 2)))
	assert_true(white_moves.has(Vector2(2, 4)))
	assert_false(white_moves.has(Vector2(2, 3)))

	_clear_board()
	chess.board[5][2] = 1
	chess.board[5][4] = 3
	var black_moves = _get_moves_for(-1, 4, 3, false)
	assert_eq(black_moves.size(), 3)
	assert_true(black_moves.has(Vector2(5, 3)))
	assert_true(black_moves.has(Vector2(5, 2)))
	assert_true(black_moves.has(Vector2(5, 4)))


func test_pawns_not_on_starting_rank_cannot_advance_two_squares():
	_clear_board()
	var white_moves = _get_moves_for(1, 4, 3)
	assert_eq(white_moves, [Vector2(3, 3)])

	_clear_board()
	var black_moves = _get_moves_for(-1, 3, 3, false)
	assert_eq(black_moves, [Vector2(4, 3)])


func test_pawns_cannot_capture_friendly_pieces_diagonally():
	_clear_board()
	chess.board[4][2] = 1
	chess.board[4][4] = 1
	var white_moves = _get_moves_for(1, 5, 3)
	assert_eq(white_moves, [Vector2(4, 3)])

	_clear_board()
	chess.board[3][2] = -1
	chess.board[3][4] = -1
	var black_moves = _get_moves_for(-1, 2, 3, false)
	assert_eq(black_moves, [Vector2(3, 3)])


func test_pawn_at_board_edge_does_not_generate_out_of_bounds_moves():
	_clear_board()
	var moves = _get_moves_for(1, 1, 0)

	assert_eq(moves, [Vector2(0, 0)])


func test_empty_square_has_no_moves():
	_clear_board()
	chess.selected_piece = Vector2(4, 4)

	assert_true(chess.get_moves().is_empty())


func test_set_move_updates_board_and_switches_turn_for_valid_move():
	_clear_board()
	chess.board[6][0] = 1
	chess.selected_piece = Vector2(6, 0)
	chess.moves = [Vector2(5, 0)]
	chess.state = true

	chess.set_move(5, 0)

	assert_eq(chess.board[6][0], 0)
	assert_eq(chess.board[5][0], 1)
	assert_false(chess.white)
	assert_false(chess.state)


func test_set_move_rejects_destination_not_in_available_moves():
	_clear_board()
	chess.board[6][0] = 1
	chess.selected_piece = Vector2(6, 0)
	chess.moves = [Vector2(5, 0)]
	chess.state = true

	chess.set_move(5, 1)

	assert_eq(chess.board[6][0], 1)
	assert_eq(chess.board[5][1], 0)
	assert_true(chess.white)
	assert_false(chess.state)


func test_board_coordinate_conversion_round_trips_every_square():
	for row in range(8):
		for col in range(8):
			var local_position = chess.board_to_local_position(row, col)
			assert_eq(
				chess.local_to_board_position(local_position),
				Vector2(row, col)
			)


func test_local_to_board_position_rejects_points_outside_board():
	assert_eq(chess.local_to_board_position(Vector2(-72.1, 0)), null)
	assert_eq(chess.local_to_board_position(Vector2(72, 0)), null)
	assert_eq(chess.local_to_board_position(Vector2(0, -72.1)), null)
	assert_eq(chess.local_to_board_position(Vector2(0, 72)), null)
