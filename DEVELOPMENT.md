# Desenvolvimento

Guia para quem vai mexer no código do WorkMachine. Para instalar e usar, veja o [README](README.md).

## Stack

Ruby 4.0, Rails 8.1, Hotwire (Turbo e Stimulus) com importmap, Tailwind, SQLite com Solid
Queue/Cache/Cable (o Solid Queue roda dentro do Puma com `SOLID_QUEUE_IN_PUMA=1`). Testes com RSpec,
FactoryBot, WebMock e SimpleCov (o build falha abaixo de 90% de cobertura de linhas).

## Rodar em desenvolvimento

Com Docker, o código fica montado no container e recarrega a cada mudança:

```bash
docker compose -f docker-compose.dev.yml up -d --build
docker compose -f docker-compose.dev.yml logs -f web
docker compose -f docker-compose.dev.yml exec web bin/rails console
```

Com a linha `COMPOSE_FILE=docker-compose.dev.yml` num `.env` na raiz do projeto, basta `docker compose up -d`. Reconstrua a imagem
(`--build`) depois de mudar o Gemfile. No WSL, mantenha o projeto dentro do Linux (por exemplo em
`~/WorkMachine`), não em `/mnt/c`.

Sem Docker, com o Ruby da `.ruby-version` instalado:

```bash
bin/setup                     # gems, banco e bin/dev
SOLID_QUEUE_IN_PUMA=1 bin/dev # app + Tailwind + jobs em localhost:3000
bundle exec rspec             # testes
bin/ci                        # RuboCop, RSpec, auditorias de gems e importmap, Brakeman
```

Tarefas úteis:

```bash
bin/rails jobs:fetch          # busca vagas agora (FORCE=1 ignora os intervalos mínimos)
bin/rails jobs:rescore        # recalcula as notas com o perfil atual
bin/rails linkedin:import     # importa os alertas do Gmail agora
bin/rails "linkedin:parse[alerta.eml]"   # mostra o que o parser lê de um alerta (não salva)
bin/rails extension:zip       # pacote da extensão para a Chrome Web Store (ficha em .github/chrome-web-store/)
bin/rails backup:now          # backup do banco
bin/rails target_companies:find          # procura os quadros das empresas das candidaturas
```

## Como o app é organizado

**O perfil é dado, não código.** Tudo o que depende de quem usa lê o `Profile` (um por instalação,
`Profile.current`):

- `app/services/job_scorer.rb`: a nota. Pontos pelos níveis das skills (`Profile::LEVELS`), termos a
  evitar, regiões aceitas, experiência relativa aos anos do perfil e títulos acima do nível. Termos são
  comparados sem acento nem maiúscula (`Profile.terms_regex`). Salvar o que pontua no perfil enfileira
  o `RescorePostingsJob`.
- `app/services/sources/`: uma classe por fonte; `Sources.all` define a ordem e `Sources.enabled` filtra
  pelo perfil (`applicable?`) e pelos Ajustes. As buscas usam `Profile#effective_search_terms` e o
  filtro de relevância `Profile#relevant?`.
- `config/areas.yml` (`Area`): pontos de partida de cada área de tecnologia (cargos, quem contrata,
  skills sugeridas, palavras dos títulos, feeds do We Work Remotely, fontes de nicho).
- `config/radar.yml` (`Radar`, `SearchTerms`): as buscas do Radar como modelos com variáveis do perfil
  (`{{stack_or}}`, `{{cargos_en_or}}`…); busca com variável vazia não aparece. Cada busca tem uma
  `key` fixa, que o perfil pode sobrescrever (`search_overrides`).
- `app/services/ai/`: prompts (`Prompt`, montados com o perfil e as vagas dos sonhos), cliente do
  OpenRouter, preços e o rascunho do perfil pelo CV (`ProfileDraft`). `app/services/cv_text.rb` lê PDF,
  DOCX e TXT.

Outras partes:

- `app/services/job_ingestor.rb`: deduplica (URL normalizada ou empresa + título), dá a nota, aplica o
  descarte automático e salva.
- `app/services/linkedin_alerts/` e `app/services/application_replies/`: Gmail por IMAP, só leitura.
- `app/models/app_keys.rb`: chaves e contas do `.env` ou de Ajustes (criptografadas com Active Record
  Encryption; as chaves de criptografia e o `secret_key_base` são gerados em
  `storage/workmachine-secrets.yml` por `config/local_secrets.rb`).
- `extension/`: a extensão Manifest V3 (veja o README dela). A versão em `manifest.json` aparece em
  Ajustes.
- `config/recurring.yml`: agregador a cada 3 horas, Gmail a cada hora, backup a cada hora e o lembrete
  de follow-up (age às 8h no fuso do perfil).

## Variáveis de ambiente

Todas opcionais. Ficam num arquivo `.env` na raiz do projeto (fora do git), que o Docker Compose lê;
depois de mudar, rode `docker compose up -d`. O que dá para configurar na tela fica em Ajustes.

| Variável | Para que serve |
| - | - |
| `OPENROUTER_API_KEY`, `OPENROUTER_MODEL` | IA. Valem mais que o que estiver em Ajustes; `OPENROUTER_MODEL` vale mais que a escolha entre o modelo gratuito e o pago. |
| `GMAIL_USER`, `GMAIL_APP_PASSWORD` | Gmail com senha de app. |
| `GMAIL_MAILBOX`, `LINKEDIN_ALERT_SENDERS` | Pasta do Gmail (padrão `INBOX`) e remetentes dos alertas. |
| `WORKMACHINE_API_TOKEN` | Token da extensão (no lugar do gerado em Ajustes). |
| `WORKMACHINE_BACKUP_DIR` | Pasta do computador onde vai o backup de hora em hora (padrão: `backups/` do projeto). Windows com WSL: `/mnt/c/Users/SEU_USUARIO/Documents/WorkMachine/backups`; macOS: `/Users/SEU_USUARIO/Documents/WorkMachine/backups`. |
| `GITHUB_TOKEN` | Aumenta o limite da API do GitHub (backend-br, frontendbr) de 60 para 5000 chamadas por hora. |
| `COMPOSE_FILE` | `docker-compose.dev.yml` para o Docker Compose usar o ambiente de desenvolvimento. |

## Testes e CI

`bundle exec rspec` precisa ficar verde e acima de 90% de cobertura. Os testes não acessam a rede
(WebMock); as respostas das fontes ficam em `spec/fixtures/sources/`. Todo teste começa com um perfil de
exemplo (`spec/support/profile.rb`, factory `:profile`).

O GitHub Actions roda Brakeman, bundler-audit, importmap audit, RuboCop, RSpec e a construção da imagem
de produção a cada push na `main` e em cada pull request.

## Imagem e versões

- `Dockerfile` é a imagem de produção (a que as pessoas instalam); `Dockerfile.dev` e
  `docker-compose.dev.yml` são para desenvolvimento.
- Para lançar uma versão: atualize `VERSION`, faça o commit e crie a tag (`git tag v2.1.0 && git push
  --tags`). O workflow `Imagem Docker` publica `ghcr.io/will-terra/workmachine` com a versão e `latest`
  (amd64 e arm64). Crie também a release no GitHub: é por ela que Ajustes avisa que há versão nova.
- O pacote no GHCR precisa estar público para quem instala baixar sem login.
- Os READMEs (inglês e português) explicam e mostram; o passo a passo de uso fica em `GUIDE.md` e
  `GUIDE.pt-BR.md`. Os prints usam dados fictícios e são refeitos com `script/readme/`, nas duas
  línguas (instruções no topo de cada arquivo).
