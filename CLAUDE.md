# WorkMachine

App de busca de emprego para pessoas de tecnologia que roda no próprio computador (cada pessoa clona e é o seu próprio servidor): agrega vagas de fontes públicas, dá nota pelo perfil da pessoa, controla candidaturas (kanban e planilha), gera mensagens e usa IA para montar o perfil a partir do currículo, analisar vagas e adaptar o CV.

## Decisões já tomadas (não perguntar de novo)

- **Stack:** Rails 8.1 + Hotwire (Turbo/Stimulus), importmap, Tailwind, SQLite com Solid Queue/Cache/Cable. Ruby 4.0.
- **Formato:** roda via Docker Compose (Windows com WSL2, macOS ou Linux), acessado em `localhost:3000` e instalável como app (PWA). Uma instalação = uma pessoa; não há contas nem servidor central.
- **Perfil como dado:** nada do usuário fica no código. A nota (`JobScorer`), os termos das fontes (`app/services/sources/`), as buscas do Radar (`config/radar.yml`, com variáveis como `{{stack_or}}`), a rotina e os prompts da IA leem o `Profile`. Os pontos de partida de cada área ficam em `config/areas.yml`. Skills em três níveis: essencial +30, importante +10, extra +5.
- **Áreas:** só tecnologia (desenvolvimento, QA, DevOps/SRE/cloud, dados, UX/UI e produto).
- **Testes:** RSpec + FactoryBot + WebMock + SimpleCov (mínimo de 90% de linhas), CI no GitHub Actions com RuboCop omakase, Brakeman e bundler-audit. Testes nunca acessam a rede.
- **LinkedIn:** sem scraping e sem candidatura automática (violam os termos e arriscam a conta). Em vez disso: a extensão (`extension/`, Manifest V3) lê a página só quando a pessoa clica; os alertas de vaga chegam pelo Gmail (IMAP, só leitura); o Radar gera links de busca prontos.
- **IA:** OpenRouter. Padrão: modelo gratuito (`Ai::Client::FREE_MODELS`, com `openrouter/free` como reserva); em Ajustes dá para mudar para o pago, `deepseek/deepseek-v4-pro-0813` ou outro modelo digitado (`OPENROUTER_MODEL` vale mais que os dois). Só roda quando a pessoa clica (a classificação das respostas das empresas roda sozinha), mostra o custo antes e nunca inventa experiência.
- **Chaves:** a pessoa digita em Ajustes (criptografadas no banco com chaves geradas em `storage/workmachine-secrets.yml`); variáveis do `.env` valem mais: `OPENROUTER_API_KEY`, `OPENROUTER_MODEL`, `GMAIL_USER`, `GMAIL_APP_PASSWORD`, `WORKMACHINE_API_TOKEN`.
- **Licença:** AGPL-3.0. **Repositório:** `will-terra/WorkMachine`.

## Convenções

- Código, nomes de tabelas e classes em inglês; mensagens de commit em português.
- **Idiomas:** interface em pt-BR e inglês (`LocalePreference`: automático pelo navegador, `pt-*` → pt-BR, o resto → en; Ajustes → Idioma força um). Todo texto de tela vai em `config/locales/<idioma>/<área>.yml`, nas duas línguas; os testes falham com tradução faltando. Na extensão, `extension/_locales/`.
- Assunto do commit começa com `Feat:`, `Fix:`, `Chore:` ou `Docs:`. Commits pequenos, cada um com os testes passando.
- Nenhum dado pessoal no git: perfis, CVs e chaves ficam no banco local, em `docs/` ou no `.env` (todos fora do git). Contexto pessoal para o Claude vai em `CLAUDE.local.md` (fora do git).
