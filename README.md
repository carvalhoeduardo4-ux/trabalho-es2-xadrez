# ♟️ Projeto Xadrez 

## 1. Visão Geral
O nosso jogo dará suporte a 3 modos de partida:
* **Humano vs Humano:** Apenas validação de regras e interface gráfica.
* **Humano vs IA:** O jogador enfrenta a IA com níveis de dificuldade configuráveis.
* **IA vs IA:** Duas instâncias do algoritmo jogam entre si.

---

## 2. O que eu fiz
O cérebro da Inteligência Artificial já foi quase inteiramente projetado e implementado em Python. O módulo conta com 3 funções prontas:

* `avaliar_tabuleiro(tabuleiro, cor_ia)`: Função de heurística que analisa o saldo de peças no tabuleiro em relação à cor jogada pela IA.
* `minimax(tabuleiro, profundidade, maximizando, cor_ia)`: Algoritmo de decisão recursivo que simula cenários futuros de jogo.
* `escolher_melhor_jogada(tabuleiro, profundidade, cor_ia)`: Função "casca" (ponto de entrada) que a Interface Gráfica chamará quando for o turno do computador. Devolve a jogada concreta a ser executada na tela.

### Controle de Dificuldade
O controle de dificuldade será definido pela profundidade. Quanto mais profundo, mais a IA consegue ver jogadas à frente:
* **Fácil:** Apenas seleciona uma jogada aleatória válida (`random.choice`).
* **Médio:** `escolher_melhor_jogada(tabuleiro, 2, cor_ia)` (profundidade rasa).
* **Difícil:** `escolher_melhor_jogada(tabuleiro, 4, cor_ia)` (profundidade mais profunda).

> **Evoluções futuras da IA:** Quero implementar ainda um sistema de poda (Alfa-Beta) para diminuir o tempo em que a IA fica calculando e aprimorar o sistema de pontuação (por exemplo, considerar que um cavalo no centro vale mais que na borda).

---

## 3. Integração (O que a IA precisa para funcionar)

### A. Estrutura das Peças
Cada casa ou objeto peça do tabuleiro precisa expor pelo menos estes dois atributos:
* `.cor`: `"brancas"` ou `"pretas"`
* `.tipo`: `"peao"`, `"cavalo"`, `"bispo"`, `"torre"`, `"dama"` ou `"rei"`

### B. Funções do Motor de Regras

* **`gerar_movimentos_legais(tabuleiro, cor)`**
  * *O que o Motor faz:* Varre a matriz 8x8 e devolve uma lista de todos os movimentos válidos para a cor informada.
  * *O que a IA espera receber:* Uma lista com tuplas de coordenadas. Exemplo: `[((1, 4), (3, 4)), ...]`.

* **`simular_movimento(tabuleiro, movimento)`**
  * *O que o Motor faz:* Recebe um estado atual, aplica o movimento e devolve uma cópia isolada do novo tabuleiro, sem alterar a partida real.

* **`verificar_estado_jogo(tabuleiro)`**
  * *O que o Motor faz:* Checa o status atual do jogo e retorna uma string (`"xeque-mate"`, `"xeque"` ou `"em jogo"`).

---

## 4. Divisão de Tarefas

### Frente 1: Motor de Regras e Tabuleiro (Lógica do Jogo)
* **Foco:** Representação de dados e validação mecânica.
* **Tarefas principais:**
  * Definir a estrutura do tabuleiro (matriz 8x8) e criação das peças.
  * Implementar a função `gerar_movimentos_legais(tabuleiro, cor)`.
  * Implementar `simular_movimento(tabuleiro, movimento)` usando `deepcopy`.
  * Implementar a checagem de limites, colisão e detecção de xeque-mate.

### Frente 2: Interface Gráfica, Menus e Loop do Jogo
* **Foco:** Experiência do usuário e ciclo de vida do jogo.
* **Tarefas principais:**
  * Tela Inicial: Seleção do Modo de Jogo (PvP, PvE, EvE) e Nível da IA (Fácil, Médio, Difícil).
  * Renderização do tabuleiro e peças na tela.
  * Mapeamento de cliques do mouse para seleção e movimentação.
  * Gerenciamento do Loop Principal de Turnos:
  * * Se for o turno da IA $\rightarrow$ chama `escolher_melhor_jogada(...)` e aplica a jogada.
    * Se for o turno do Humano $\rightarrow$ aguarda o evento do mouse.
  ---

##  Estrutura de Pastas e Arquivos

```text
TRABALHO-ES2-XADREZ/
├── main.py                    # Ponto de entrada (integra GUI, Lógica e IA)
├── requirements.txt           # Dependências do projeto (ex: pygame)
├── .gitignore                 # Arquivos ignorados pelo Git
├── README.md                  # Documentação e regras de integração
│
├── ia/                        # Módulo de Inteligência Artificial (Minimax e Heurística)
│   ├── __init__.py
│   ├── minimax.py             # Algoritmo de decisão e escolha de jogadas
│   └── avaliacao.py           # Avaliação heurística do tabuleiro
│
├── logica/                    # Motor de Regras e Tabuleiro
│   ├── __init__.py
│   ├── peca.py                # Classe Peca (.cor e .tipo)
│   ├── tabuleiro.py           # Estado do tabuleiro e simular_movimento()
│   └── regras.py              # gerar_movimentos_legais() e checagem de xeque
│
└── gui/                       # Interface Gráfica e Eventos
    ├── __init__.py
    ├── interface.py           # Renderização do tabuleiro e peças na tela
    ├── menu.py                # Telas de navegação e seleção de dificuldade
    └── assets/                # Imagens das peças (.png)
    * Se for o turno da IA $\rightarrow$ chama `escolher_melhor_jogada(...)` e aplica a jogada.
    * Se for o turno do Humano $\rightarrow$ aguarda o evento do mouse.
