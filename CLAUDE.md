# WorkMachine

App pessoal do Ana Souza para automatizar a busca de emprego: agrega vagas, dá nota pela stack dele, controla candidaturas (kanban/planilha), gera mensagens e usa IA para adaptar CV e abordagens.

O plano completo de implementação está em `docs/PLANO.md`. Toda a pesquisa de buscas, plataformas, consultorias, grupos, templates e rotina já feita está em `docs/radar-vagas-rails.html`.

## Usuário

- Ana Souza, Full Stack Engineer, cerca de 3 anos de experiência. Mora em Curitiba/PR, Brasil. Fala português (nativo), inglês e espanhol (fluentes).
- Busca vaga **Pleno / Mid-level**, remota (Brasil ou internacional com pagamento em dólar). Plano B: front-end React/Next.js/TypeScript.
- Ambiente: Windows + WSL2 (Ubuntu), Docker Compose, VS Code.
- Responda sempre em português do Brasil.

## Decisões já tomadas (não perguntar de novo)

- **Stack:** Rails 8.1 + Hotwire (Turbo/Stimulus), importmap, SQLite com Solid Queue/Cache/Cable. Ruby 4.0 se estiver instalado no WSL; senão, a versão disponível ≥ 3.3.
- **Formato:** roda via Docker Compose no WSL2, acessado no navegador em `localhost:3000` e instalável como app no Windows (PWA do Rails 8).
- **Testes:** RSpec + FactoryBot + SimpleCov (meta 90%+), CI no GitHub Actions. É o padrão que ele usa no trabalho.
- **LinkedIn:** sem scraping e sem auto-apply (violam os termos e arriscam a conta). Em vez disso:
  1. extensão Chrome/Edge (Manifest V3) com botão "Salvar no WorkMachine" na vaga aberta;
  2. importação dos e-mails de alerta de vagas do LinkedIn via IMAP do Gmail (senha de app);
  3. gerador de links de busca prontos (o "Radar").
- **Funcionalidades da v1:** agregador automático de vagas, kanban/planilha com exportação .xlsx, mensagens e rotina, IA via OpenRouter com o modelo `deepseek/deepseek-v4-pro-0813` (em 20/10/2026 saiu a Claude API e depois o Claude Sonnet, por custo; GLM 5.3 é a alternativa via `OPENROUTER_MODEL`).
- **Repositório:** `will-terra/WorkMachine`.

## Convenções

- Código, nomes de tabelas e classes em inglês; interface em português.
- Segredos só em variáveis de ambiente (`.env`, fora do git): `OPENROUTER_API_KEY`, `GMAIL_USER`, `GMAIL_APP_PASSWORD`, `WORKMACHINE_API_TOKEN`.
- Commits pequenos por marco (ver ordem em `docs/PLANO.md`), cada um com testes passando.
