# Para agentes de IA

Antes de mexer no projeto, leia [docs/ESTADO_DO_PROJETO.md](docs/ESTADO_DO_PROJETO.md), principalmente a seção 6 ("Para devs e agentes de IA"). Ela tem as regras de trabalho, os limites de conteúdo, os branches, a organização do código, como rodar o Godot e os testes.

Resumo do essencial:
- Tudo em português (BR), em linguagem simples.
- Godot 4.7.2. Branch principal: `claude/project-thread-o4s5hf` (não existe `main`).
- Personagens: desde 11/11/2026 os 42 atletas têm `.vrm` do VRoid em `personagens/<time>/`. O gerado por código (`dados/aparencia.json`) só entra se faltar o `.vrm`.
- Handoff mais recente: [docs/HANDOFF.md](docs/HANDOFF.md).
- Rode todos os testes de `testes/` antes de subir qualquer mudança.
