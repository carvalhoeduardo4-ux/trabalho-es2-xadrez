# trabalho-es2-xadrez

1.Visão Geral
O nosso jogo dará suporte a 3 modos de partida:
	Humano vs Humano: Apenas validação de regras e interface gráfica.
	Humano vs IA: O jogador enfrenta a IA com níveis de dificuldade configuráveis.
	IA vs IA: Duas instâncias do algoritmo jogam entre si.

2. O que eu fiz
O cérebro da Inteligência Artificial já foi quase inteiramente projetado e implementado em Python. O módulo conta com 3 funções prontas:

  avaliar_tabuleiro(tabuleiro, cor_ia): Função de heurística que analisa o saldo de peças no tabuleiro em relação à cor jogada pela IA.
	minimax(tabuleiro, profundidade, maximizando, cor_ia): Algoritmo de decisão recursivo que simula cenários futuros de jogo.
	escolher_melhor_jogada(tabuleiro, profundidade, cor_ia): Função "casca" (ponto de entrada) que a Interface Gráfica chamará quando for o turnodo computador.        Devolve a jogada concreta a ser executada na tela.

Controle de Dificuldade:
O controle de dificuldade será definido pela profundidade, quanto mais profundo, mais a IA consegue ver jogadas a frente. Podemos definir:
 Fácil: Apenas seleciona uma jogada aleatória válida.
 Médio: escolher_melhor_jogada(tabuleiro, 2, cor_ia) (profundidade rasa).
 Difícil: escolher_melhor_jogada(tabuleiro, 4, cor_ia) (profundidade mais profunda).

Quero implementar ainda um sistema de poda para diminuir o tempo em que a IA ficará “pensando” e melhorar o sistema de pontos (por exemplo, um cavalo no meio do tabuleiro vale mais do que um cavalo na beira do tabuleiro onde seus movimentos são limitados)

3. Integração (O que a IA precisa para funcionar)
A. Estrutura das Peças
Cada casa ou objeto peça do tabuleiro precisa expor pelo menos estes dois atributos:
	.cor: "brancas" ou "pretas".
	.tipo: "peao", "cavalo", "bispo", "torre", "dama" ou "rei".

B. Funções de Regras do Jogo Necessárias
gerar_movimentos_legais(tabuleiro, cor)	-> O que o Motor faz: Varre a matriz 8x8 e devolve uma lista de todos os movimentos válidos para quem está jogando.
O que a IA espera receber: Uma lista, de preferência com tuplas de coordenadas. Exemplo: [((1, 4), (3, 4)), ...].

simular_movimento(tabuleiro, movimento) ->	O Minimax precisa testar as jogadas na árvore de possibilidades sem alterar o tabuleiro real que o usuário está vendo. Essa função deve receber um estado atual, aplicar o movimento e devolver uma cópia do novo tabuleiro.

verificar_estado_jogo(tabuleiro) ->	O que o Motor faz: Checa se o jogo acabou naquele cenário.
O que a IA espera receber: Algo simples, como um texto ("xeque-mate", "xeque" ou "em jogo"). Assim a IA sabe que chegou no fundo da árvore e precisa parar de calcular.

4.Divisões
Frente 1: Motor de Regras e Tabuleiro (Lógica do Jogo)
	Foco: Representação de dados e validação mecânica.
	Tarefas principais:
	Definir a estrutura do tabuleiro (matriz 8x8) e criação das peças.
	Implementar a função gerar_movimentos_legais(tabuleiro, cor) para cada tipo de peça.
	Implementar simular_movimento(tabuleiro, movimento) utilizando deepcopy para não afetar o jogo real.
	Implementar a checagem de limites, colisão e detecção de xeque-mate.

Frente 2: Interface Gráfica, Menus e Loop do Jogo
	Foco: Experiência do usuário e ciclo de vida do jogo.
	Tarefas principais:
	Tela Inicial: Seleção do Modo de Jogo (PvP, PvE, EvE) e Nível da IA (Fácil, Médio, Difícil).
	Renderização do tabuleiro e peças na tela.
	Mapeamento de cliques do mouse para seleção e movimentação de peças no modo humano.
	Gerenciamento do Loop Principal de Turnos:
	Se for o turno da IA → chama escolher_melhor_jogada(...) e aplica a jogada.
	Se for o turno do Humano → aguarda evento do mouse.
