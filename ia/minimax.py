def minimax(tabuleiro,profundidade,maximizando, cor_ia):
    
    if(profundidade == 0 or verificar_estado_jogo(tabuleiro) == "xeque-mate"):
        return avaliar_tabuleiro(tabuleiro,cor_ia) 
    
    cor_oponente = "pretas" if cor_ia == "brancas" else "brancas"
    
    if maximizando:
        maior_nota = float('-inf')
        lst_movimentos = gerar_movimentos_legais(tabuleiro,cor_ia)
        
        for movimento in lst_movimentos:
            novo_tabuleiro = simular_movimento(tabuleiro,movimento)
            nota = minimax(novo_tabuleiro, profundidade-1,False,cor_ia)
            maior_nota = max(maior_nota,nota)
        
        return maior_nota 
    
    else:
        menor_nota = float('inf')
        lst_movimentos = gerar_movimentos_legais(tabuleiro,cor_oponente)
        
        for movimento in lst_movimentos:
            novo_tabuleiro = simular_movimento(tabuleiro,movimento)
            nota = minimax(novo_tabuleiro,profundidade-1,True,cor_ia)
            menor_nota = min(menor_nota,nota)
        
        return menor_nota
            
            
def escolher_melhor_jogada(tabuleiro,profundidade, cor_ia):
    
    melhor_nota = float('-inf')
    melhor_movimento = None 
    
    lst_movimentos = gerar_movimentos_legais(tabuleiro,cor_ia)
    
    for movimento in lst_movimentos:
        novo_tabuleiro = simular_movimento(tabuleiro,movimento)
        nota = minimax(novo_tabuleiro,profundidade-1,False,cor_ia)
        if nota > melhor_nota:
            melhor_nota = nota
            melhor_movimento = movimento
    
    return melhor_movimento