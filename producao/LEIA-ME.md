# Produção dos personagens

| Pasta ou arquivo | O que é |
| --- | --- |
| `MANIFESTO.md` | Estado real dos 42 atletas. Gerado por `python3 ferramentas/manifesto.py`. |
| `status.json` | O que foi conferido fora do repositório (VRoid, `.vroid`, Godot, animação). |
| `fichas/<time>/<nn>_<nome>.md` | Ficha visual de cada atleta: alvo de corpo, rosto, cabelo e uniforme. |
| `uniformes/<time>/numeros/<nn>.png` | Número de cada camisa, fundo transparente, pra importar como camada no VRoid. |
| `uniformes/<time>/previa.png` | Os 6 uniformes do time desenhados chapados, pra conferir cores e números. |
| `capturas/<time>/<nn>_<nome>_<vista>.png` | Capturas reais do modelo (VRoid e Godot). |

Os números e prévias saem de `python3 ferramentas/uniformes.py` (precisa do Pillow).
A textura final da camisa depende do mapa UV que o próprio VRoid exporta, então ela só
é feita no PC de casa, com o VRoid aberto.

Os projetos editáveis `.vroid` não vão pro Git: ficam no PC de casa em
`VoleiPersonagens/vroid/<time>/<nn>_<nome>.vroid`, prontos pra subir no Drive.
