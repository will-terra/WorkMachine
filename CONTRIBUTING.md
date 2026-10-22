# Contribuindo

Obrigado pelo interesse! O WorkMachine é mantido no tempo livre, então issues claras e pull requests
pequenos ajudam muito.

## Problemas e sugestões

- Antes de abrir, procure se já existe uma issue parecida.
- Use os modelos de issue: **Problema** (com os passos para reproduzir, o que esperava e o que
  aconteceu) ou **Sugestão**.
- Nunca cole chaves, senhas, currículos ou dados pessoais numa issue. Para logs, use
  `docker compose logs web` e apague o que for pessoal.

## Pull requests

1. Faça um fork e crie um branch a partir da `main`.
2. Prepare o ambiente seguindo o [DEVELOPMENT.md](DEVELOPMENT.md).
3. Escreva testes para o que mudar. `bin/ci` precisa passar: RuboCop, RSpec (com 90% de cobertura),
   Brakeman e as auditorias.
4. Commits pequenos, com o assunto começando por `Feat:`, `Fix:`, `Chore:` ou `Docs:`. Mensagens e
   interface em português; código em inglês.
5. Abra o pull request explicando o porquê da mudança. O CI roda sozinho.

## Princípios do projeto

- **Cada pessoa no próprio computador.** Nada de servidor central nem de dados saindo da máquina sem a
  pessoa pedir.
- **O perfil é dado.** Nada que dependa de quem usa vai para o código: lê-se do `Profile`.
- **LinkedIn:** sem scraping e sem candidatura automática. A extensão só lê a página quando a pessoa
  clica.
- **Fontes de vagas:** só APIs e feeds públicos, respeitando os limites e os créditos que cada uma pede.
- **IA:** só com o clique (e o custo à vista), sem inventar experiência.

## Licença

Ao contribuir, você concorda que a sua contribuição seja distribuída sob a [GNU AGPL-3.0](LICENSE), a
licença do projeto.
