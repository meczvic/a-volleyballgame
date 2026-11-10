# Produção dos personagens

| Pasta ou arquivo | O que é |
| --- | --- |
| `MANIFESTO.md` | Estado real dos 42 atletas. Gerado por `python3 ferramentas/manifesto.py`. |
| `status.json` | O que foi conferido de verdade, por atleta: gerado, importado (VRM), animado, em partida. |
| `fichas/<time>/<nn>_<nome>.md` | Ficha visual de cada atleta: alvo de corpo, rosto, cabelo e uniforme. |
| `uniformes/<time>/numeros/<nn>.png` | Número de cada camisa, fundo transparente, pra importar como camada no VRoid. |
| `uniformes/<time>/previa.png` | Os 6 uniformes do time desenhados chapados, pra conferir cores e números. |
| `capturas/<time>/folha.png` | Folha de contato do time (os 6 de frente e de costas), renderizada pelo jogo com `ferramentas/capturas.gd`. |
| `capturas/<time>/<nn>_<nome>_<vista>.png` | Vistas de cada atleta (frente, perfil, três quartos, costas, correr, cortada), renderizadas pelo jogo. No Git só as do Karasuno, pra não pesar; as outras saem de `godot --path . --script res://ferramentas/capturas.gd -- todos`. |

Os números e prévias saem de `python3 ferramentas/uniformes.py` (precisa do Pillow).
A textura final da camisa depende do mapa UV que o próprio VRoid exporta, então ela só
é feita no PC de casa, com o VRoid aberto.

Os projetos editáveis `.vroid` não vão pro Git: ficam no PC de casa em
`VoleiPersonagens/vroid/<time>/<nn>_<nome>.vroid`, prontos pra subir no Drive.
