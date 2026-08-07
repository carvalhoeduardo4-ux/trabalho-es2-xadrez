def avaliar_tabuleiro(tabuleiro, cor_ia):
    pontuacao = 0
    valores_pecas = {
        'peao' : 1,
        'cavalo' : 3,
        'bispo' : 3,
        'torre' : 5,
        'dama' : 9,
        'rei' : 1000
    }
    
    for peca in tabuleiro:
        if peca is not None:
            if peca.cor == cor_ia:
                pontuacao += valores_pecas[peca.tipo]
            else:
                pontuacao -= valores_pecas[peca.tipo] 
    return pontuacao