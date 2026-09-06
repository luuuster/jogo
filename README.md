# Crônicas de Lúmen — protótipo tático

MVP original de uma batalha tática 2D, feito em **Godot 4 + GDScript**. Dois guardiões defendem o Farol de Lúmen contra três invasores em um tabuleiro 10×10. Todo o conteúdo, nomes e apresentação deste repositório são originais.

## Escopo do MVP

- mapa 10×10 com terreno de custo variável e obstáculos;
- dois heróis e três inimigos, com ordem por velocidade;
- movimento por Dijkstra, ataques corpo a corpo/à distância e previsão de dano;
- uma habilidade por arquétipo (guerreiro, arqueiro e mago);
- IA heurística, vitória/derrota, reinício e retorno ao menu.

Altura, flanqueamento, progressão, campanha e salvamento ficam explicitamente fora deste MVP.

## Instalação e execução

1. Instale o [Godot Engine 4.3 ou superior](https://godotengine.org/download/) (a edição padrão, sem C#, é suficiente).
2. Importe `project.godot` no Project Manager.
3. Abra o projeto e pressione **F6** ou **F5**.

Ou pela linha de comando:

```bash
godot --path .
```

## Baixar ou gerar um executável

O projeto possui presets para **Windows**, **Linux** e **Web**. No GitHub, abra a aba **Actions**, escolha **Gerar executáveis**, clique em **Run workflow** e, ao final, baixe o artefato `Cronicas-de-Lumen`. Dentro dele estão:

- `Cronicas-de-Lumen-Windows.zip`: extraia todos os arquivos e abra `Cronicas-de-Lumen.exe`;
- `Cronicas-de-Lumen-Linux.tar.gz`: extraia e execute `Cronicas-de-Lumen.x86_64`;
- `web/`: versão para publicar em um servidor web.

Para gerar tudo localmente, instale também os **Export Templates** da mesma versão do Godot (menu **Editor > Manage Export Templates**) e execute:

```bash
./scripts/build_exports.sh
```

Os arquivos serão criados em `build/`. Também é possível usar **Project > Export** no editor e escolher Windows, Linux ou Web.

## Como jogar

Clique em **Iniciar batalha**. Durante o turno de um aliado, clique em uma casa azul para mover; depois escolha **Ataque** ou **Habilidade**, selecione um alvo destacado e confirme. Clique com o botão direito ou use **Cancelar** para voltar. Inimigos agem automaticamente. Elimine os três invasores antes que ambos os guardiões caiam.

## Estrutura

```text
scenes/             cenas de entrada
scripts/battle/     fluxo de turnos, combate e condições
scripts/grid/       células, conversão visual e pathfinding
scripts/units/      modelo orientado a dados das unidades
scripts/ai/         decisões heurísticas
resources/          configurações JSON
assets/             arte, áudio e efeitos originais (placeholders no MVP)
tests/              testes das regras sem cenas
```

## Validação

Com Godot disponível, execute:

```bash
godot --headless --path . --script tests/test_rules.gd
```

## Marcos

- [x] 1. Tabuleiro e seleção de casas
- [x] 2. Unidades e movimento
- [x] 3. Combate local
- [x] 4. Turnos, condições e IA
- [x] 5. Interface e feedback visual básico
- [ ] 6. Build jogável distribuível (depende de export templates e playtest)
