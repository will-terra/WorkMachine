# WorkMachine

App pessoal para a busca de emprego do Ana Souza. Junta vagas de várias fontes, dá uma nota de
0 a 100 pela stack dele, controla as candidaturas num kanban (com exportação para planilha), monta
mensagens para recrutadores e usa IA para analisar a vaga e adaptar o resumo do CV.

Roda localmente com Docker Compose dentro do WSL2, em `http://localhost:3000`, e pode ser instalado
como aplicativo no Windows.

## O que tem

| Tela | Para que serve |
| - | - |
| **Painel** | Vagas novas por nota, follow-ups do dia, funil das candidaturas e a rotina de hoje. |
| **Vagas** | Triagem: filtros por fonte, região, senioridade e nota. Salvar (vira candidatura), Descartar, Analisar com IA. |
| **Candidaturas** | Kanban por status (arrastar e soltar), tabela, exportação `.xlsx`, importação e exportação CSV. |
| **Radar** | O que fazer à mão, por frequência (todo dia, toda semana, uma vez): buscas prontas no LinkedIn, Telegram, X e Google, sites sem API, alertas do LinkedIn a criar e o checklist de cadastros. No topo, o resumo das fontes automáticas. |
| **Mensagens** | Modelos com `{{nome}}`, `{{cargo}}` e `{{empresa}}` preenchidos a partir da vaga ou do contato, com contador de caracteres. |
| **Rotina** | Checklist diário e semanal. |
| **Contatos** e **Empresas-alvo** | Recrutadores e gestores; empresas cujos quadros de vagas o agregador consulta. |
| **Ajustes** | Notificação na área de trabalho quando chegam vagas com nota igual ou maior que a escolhida (padrão 40). |

De onde vêm as vagas, sozinhas:

- **Agregador**, a cada 3 horas: Remotive, Remote OK, We Work Remotely, Remotar, Himalayas, Working
  Nomads, backend-br/vagas, frontendbr/vagas (plano B), Hacker News "Who is hiring", GoRails Jobs e os
  quadros Greenhouse, Lever, Ashby e Workable das empresas-alvo. Cada fonte respeita um intervalo mínimo (o Remotive, por exemplo, pede no máximo 4
  chamadas por dia) e toda vaga guarda o link e o crédito da fonte.
- **Alertas do LinkedIn**, a cada hora: os e-mails de alerta que chegam no Gmail são lidos por IMAP.
- **Extensão do navegador**: botão "Salvar no WorkMachine" na vaga aberta (LinkedIn, Greenhouse, Lever,
  Gupy, páginas de carreira…).

O WorkMachine não raspa o LinkedIn e não se candidata sozinho, porque isso viola os termos do LinkedIn
e arrisca a conta.

## Instalar e rodar (WSL2 + Docker)

Pré-requisitos: WSL2 com Ubuntu e o Docker Desktop com a integração do WSL ligada
(*Settings → Resources → WSL integration*). Mantenha o projeto dentro do Linux (por exemplo em
`~/WorkMachine`), não em `/mnt/c`, para o app ficar rápido.

```bash
git clone https://github.com/will-terra/WorkMachine.git ~/WorkMachine
cd ~/WorkMachine
cp .env.example .env        # depois preencha as chaves (seções abaixo)
docker compose up -d --build
```

A primeira subida leva alguns minutos (instala as gems). Depois abra **http://localhost:3000**, crie a
sua conta na tela de primeiro acesso (o app tem um único usuário) e pronto. Na criação do banco já
entram as 16 consultorias, os 7 modelos de mensagem e 7 empresas-alvo de exemplo.

O Solid Queue roda dentro do Puma (`SOLID_QUEUE_IN_PUMA=1`), então há um único container, e as
tarefas automáticas (agregador, alertas do LinkedIn e follow-ups às 8h de Brasília) rodam enquanto
ele estiver de pé. O banco SQLite fica no volume `storage` do Docker.

Comandos do dia a dia:

```bash
docker compose logs -f web                     # ver o que está acontecendo
docker compose up -d --force-recreate          # depois de editar o .env
docker compose up -d --build                   # depois de mudar o Gemfile
docker compose down                            # parar (os dados ficam no volume)
docker compose exec web bin/rails console      # console do Rails
docker compose exec web bin/rails jobs:fetch   # buscar vagas agora (FORCE=1 ignora os intervalos)
```

O botão **Buscar agora**, na tela de Vagas, faz o mesmo que `jobs:fetch` sem precisar do terminal.

### Instalar como app no Windows

Com o WorkMachine rodando, abra `http://localhost:3000` no Edge ou no Chrome:

- **Edge:** menu `…` → **Aplicativos** → **Instalar este site como um aplicativo**.
- **Chrome:** ícone de instalar na barra de endereço (ou menu `⋮` → **Transmitir, salvar e compartilhar** →
  **Instalar página como app**).

O WorkMachine ganha ícone no menu Iniciar e abre em janela própria. Ele continua dependendo do
container estar rodando; se a janela não carregar, rode `docker compose up -d` no WSL.

## Configurar o `.env`

O `.env` fica fora do git. Depois de editar, recrie o container com `docker compose up -d --force-recreate`.

| Variável | Para que serve |
| - | - |
| `OPENROUTER_API_KEY` | IA (análise de fit, resumo de CV, mensagem). |
| `OPENROUTER_MODEL` | Opcional. Modelo do OpenRouter; o padrão é `deepseek/deepseek-v4-pro-0813`. |
| `GMAIL_USER`, `GMAIL_APP_PASSWORD` | Importação dos alertas de vagas do LinkedIn. |
| `GMAIL_MAILBOX`, `LINKEDIN_ALERT_SENDERS` | Opcionais. Pasta do Gmail (padrão `INBOX`) e remetentes dos alertas. |
| `WORKMACHINE_API_TOKEN` | Token que a extensão do navegador manda para salvar vagas. |
| `GITHUB_TOKEN` | Opcional. Aumenta o limite da API do GitHub de 60 para 5000 chamadas por hora. |

### Chave do OpenRouter (IA)

1. Crie a conta em [openrouter.ai](https://openrouter.ai) e adicione créditos em
   [Settings → Credits](https://openrouter.ai/settings/credits). Alguns dólares duram muito: uma análise
   de fit com o DeepSeek V4 Pro custa por volta de US$ 0,001.
2. Gere a chave em [Settings → Keys](https://openrouter.ai/settings/keys) e coloque em `OPENROUTER_API_KEY`.
3. Para trocar de modelo, use `OPENROUTER_MODEL` com o id do OpenRouter, por exemplo `z-ai/glm-5.3`.

A IA só roda quando você clica em um dos botões da página da vaga. Antes do clique a página mostra uma
estimativa de custo, e cada resultado guarda o custo real informado pelo OpenRouter. O perfil usado nos
prompts está em [config/ai/profile.md](config/ai/profile.md): atualize esse arquivo quando o CV mudar,
porque a IA só usa fatos que estão nele.

### Senha de app do Gmail (alertas do LinkedIn)

1. Ligue a **verificação em duas etapas** na conta Google (myaccount.google.com → Segurança). Sem ela,
   o Google não oferece senha de app.
2. Abra [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords), crie uma senha
   com o nome "WorkMachine" e copie os 16 caracteres.
3. No `.env`: `GMAIL_USER=seu.email@gmail.com` e `GMAIL_APP_PASSWORD=<os 16 caracteres>`.
4. No LinkedIn, em cada busca boa do Radar, clique em **Criar alerta** e escolha receber por e-mail.

A importação abre a caixa só para leitura: os e-mails continuam como estão (nada é marcado como lido,
movido ou apagado). Na primeira vez ela olha os últimos 14 dias; depois, só o que chegou desde o último
alerta importado. Se o seu Gmail arquiva os alertas fora da caixa de entrada, use
`GMAIL_MAILBOX=[Gmail]/Todos os e-mails`.

O formato desses e-mails muda de tempos em tempos. Para conferir o que o parser lê de um alerta real,
exporte o e-mail como `.eml` (no Gmail: `⋮` → **Fazer o download da mensagem**), copie para a pasta do
projeto e rode:

```bash
docker compose exec web bin/rails "linkedin:parse[alerta.eml]"   # só mostra, não salva nada
docker compose exec web bin/rails linkedin:import                # importa agora
```

## Notificações de vagas novas

Em **Ajustes**, clique em **Ativar notificações** e aceite o pedido do navegador. Faça isso dentro do app
instalado (ou em cada navegador onde quiser receber) e use **Enviar notificação de teste** para conferir.
Sempre que o agregador ou os alertas do LinkedIn trouxerem vagas com nota igual ou maior que a nota
mínima (padrão 40), chega uma notificação; clicar nela abre a vaga, ou a triagem filtrada quando são
várias. Cada vaga é notificada uma vez só. As chaves do Web Push são geradas sozinhas no primeiro uso.

No Windows, o Chrome precisa estar rodando em segundo plano para entregar com o app fechado (é o padrão:
*Configurações → Sistema → Continuar executando apps em segundo plano*). Se nada aparecer, confira se as
notificações do Chrome estão liberadas em *Configurações do Windows → Sistema → Notificações*.

## Extensão do navegador

1. Gere um token e coloque em `WORKMACHINE_API_TOKEN` no `.env` (depois recrie o container):
   ```bash
   docker compose exec web bin/rails secret | cut -c1-48
   ```
2. O Chrome e o Edge nem sempre carregam extensões de dentro do WSL, então copie a pasta para o Windows:
   ```bash
   cp -r ~/WorkMachine/extension /mnt/c/Users/$USER/WorkMachine-extension
   ```
   (Se o seu usuário do Windows tiver outro nome que o do WSL, ajuste o caminho.)
3. Abra `chrome://extensions` ou `edge://extensions`, ligue o **Modo do desenvolvedor**, clique em
   **Carregar sem compactação** e escolha `C:\Users\<você>\WorkMachine-extension`.
4. Fixe o ícone na barra, abra as **Opções** da extensão, cole o token e clique em **Testar conexão**.

Para usar: abra a vaga, clique no ícone, confira título, empresa e local e clique em
**Salvar no WorkMachine**. Quando a extensão mudar, copie a pasta de novo e clique em recarregar na
página de extensões. Detalhes em [extension/README.md](extension/README.md).

## Empresas-alvo

São as empresas que publicam vagas num quadro público do Greenhouse, Lever, Ashby ou Workable. O
agregador consulta cada empresa ativa a cada 3 horas e guarda só as vagas de engenharia.

Elas também entram sozinhas: quando qualquer vaga nova (do agregador, de um alerta ou salva pela
extensão) aponta para o quadro de uma empresa, ela é cadastrada. Se a vaga tiver nota igual ou maior
que a nota mínima de **Ajustes**, a empresa já entra ativa; senão aparece em **Sugestões**, com os botões
Ativar e Ignorar.

1. Abra **Empresas-alvo** → **Adicionar empresa**.
2. Escolha o sistema e informe o *slug*, que é o trecho do endereço da página de vagas:
   - Greenhouse: `job-boards.greenhouse.io/`**`gitlab`**
   - Lever: `jobs.lever.co/`**`empresa`**
   - Ashby: `jobs.ashbyhq.com/`**`empresa`**
   - Workable: `apply.workable.com/`**`empresa`**
3. Salve. A empresa entra na próxima busca (ou clique em **Buscar agora** em Vagas).

As 7 empresas do seed estão marcadas como "exemplo"; edite, desative ou apague à vontade. Se o slug
estiver errado, o aviso aparece em **Vagas → Fontes do agregador**.

## Nota das vagas

A nota vem de [app/services/job_scorer.rb](app/services/job_scorer.rb) e cada vaga mostra os pontos que
somaram ou tiraram:

- Palavras-chave: Rails +30, Ruby +10, React +10, Hotwire/Turbo/Stimulus +8, Sidekiq +5, Postgres +5,
  GovTech +5, TypeScript +4, Docker/Kubernetes +3.
- Região aberta (LATAM, Brasil, anywhere, worldwide) +15.
- Penalidades: só EUA/Canadá, só Europa ou lista de países fora da América Latina −40; 7+ anos −15;
  cargo de gestão −15; staff/principal −10.

Depois de mudar os pesos, recalcule as vagas já salvas com
`docker compose exec web bin/rails jobs:rescore`.

## Backup

A cada hora (no minuto 30) o WorkMachine copia o banco para a pasta de `WORKMACHINE_BACKUP_DIR` no
`.env`, por exemplo `/mnt/c/Users/<você>/Documents/WorkMachine/backups` (sem a variável, vai para
`backups/` do projeto). Ficam todas as cópias das últimas 24 horas e uma por dia dos últimos 14 dias.
Em **Ajustes** aparecem o último backup e o botão **Fazer backup agora**; pelo terminal,
`docker compose exec web bin/rails backup:now`. Depois de mudar a pasta no `.env`, rode
`docker compose up -d` para o container montar a pasta nova.

Para restaurar uma cópia (troque o nome do arquivo):

```bash
docker compose stop web
docker compose run --rm --no-deps --entrypoint sh web -c \
  'cp backups/workmachine-AAAA-MM-DD-HHMM.sqlite3 storage/development.sqlite3 && rm -f storage/development.sqlite3-wal storage/development.sqlite3-shm'
docker compose start web
```

A planilha das candidaturas também sai em **Candidaturas → Exportar .xlsx** ou **Exportar CSV**.

Esqueceu a senha? Não há envio de e-mail; troque pelo terminal:

```bash
docker compose exec web bin/rails runner 'User.first.update!(password: "uma-senha-nova")'
```

## Desenvolvimento

Ruby 4.0, Rails 8.1, Hotwire (Turbo e Stimulus) com importmap, Tailwind, SQLite com Solid
Queue/Cache/Cable. Testes com RSpec, FactoryBot, WebMock e SimpleCov (o build falha abaixo de 90% de
cobertura).

Fora do Docker, com o Ruby instalado no WSL:

```bash
bin/setup                     # instala as gems, prepara o banco e sobe o bin/dev
bundle exec rspec             # testes
bin/ci                        # RuboCop, RSpec, auditorias de gems e importmap, Brakeman
SOLID_QUEUE_IN_PUMA=1 bin/dev # app + Tailwind + jobs, em localhost:3000
```

O GitHub Actions roda Brakeman, bundler-audit, importmap audit, RuboCop e RSpec a cada push na `main`
e em cada pull request.

Onde fica cada coisa:

- `app/services/sources/`: uma classe por fonte de vagas; `Sources.all` define a ordem.
- `app/services/job_ingestor.rb`: deduplica (URL normalizada e empresa + título), dá a nota e salva.
- `app/services/linkedin_alerts/`: leitura do Gmail por IMAP e parser dos alertas.
- `app/services/ai/`: prompts, cliente do OpenRouter e preços; `config/ai/profile.md` é o perfil.
- `config/radar.yml` e `config/routine.yml`: buscas do Radar e itens da rotina.
- `extension/`: a extensão Manifest V3.
- `docs/PLANO.md`: o plano original e as decisões.
