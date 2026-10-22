# WorkMachine

Um assistente de busca de emprego para quem é de tecnologia (desenvolvimento, QA, DevOps/SRE/cloud,
dados, UX/UI e produto) que roda no seu próprio computador. Ele:

- junta vagas de mais de dez fontes públicas e dos seus alertas do LinkedIn;
- dá a cada vaga uma nota de 0 a 100 pelo **seu** perfil, e explica a nota;
- controla as candidaturas num kanban, com planilha `.xlsx`, follow-ups e métricas do funil;
- monta o seu perfil a partir do currículo e usa IA para analisar vagas, adaptar o resumo do CV e
  escrever mensagens para recrutadores;
- lista o que vale fazer à mão (o Radar): buscas prontas no LinkedIn, X, Google e grupos.

Tudo fica no seu computador: as vagas, o currículo e as senhas. Não há conta em servidor nenhum.

> O WorkMachine não raspa o LinkedIn e não se candidata sozinho: isso viola os termos do LinkedIn e
> arrisca a sua conta. Os alertas de vaga chegam pelo seu Gmail, e a extensão do navegador só lê uma
> página quando você clica nela.

## O que você precisa

- Um computador com **Windows 10/11, macOS ou Linux** e uns 2 GB livres.
- O **Docker Desktop** (no Linux, o Docker Engine com o plugin Compose).
- Opcional, para a IA: uma conta gratuita no [OpenRouter](https://openrouter.ai). O padrão é um modelo
  gratuito, que não precisa de crédito. Se preferir o modelo pago (DeepSeek V4 Pro), alguns dólares de
  crédito duram meses: montar o perfil pelo currículo custa menos de 1 centavo de dólar.
- Opcional, para os alertas do LinkedIn e as respostas das empresas: um Gmail com a verificação em
  duas etapas ligada.

## Instalar

1. **Instale o Docker Desktop** em [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
   e abra o programa uma vez. No Windows ele ativa o WSL2 sozinho (pode pedir para reiniciar).
2. **Baixe o WorkMachine.** Quem usa git:
   ```bash
   git clone https://github.com/will-terra/WorkMachine.git
   cd WorkMachine
   ```
   Sem git: na página do projeto no GitHub, clique em **Code → Download ZIP**, descompacte e abra um
   terminal na pasta (no Windows, clique com o botão direito na pasta → **Abrir no Terminal**).
3. **Suba o app:**
   ```bash
   docker compose up -d
   ```
   Na primeira vez ele baixa a imagem do WorkMachine (alguns minutos). Daí em diante o app sobe
   sozinho junto com o Docker.
4. Abra **http://localhost:3000**, crie a sua conta (ela só existe no seu computador) e siga o
   **Primeiro uso**: chave da IA, Gmail, perfil e a primeira busca de vagas.

### Instalar como aplicativo

Com o app aberto no Chrome ou no Edge: ícone de instalar na barra de endereço (Chrome) ou menu `…` →
**Aplicativos** → **Instalar este site como um aplicativo** (Edge). Ele ganha ícone e janela própria;
continua precisando do Docker rodando.

## Primeiros passos

1. **Perfil.** Envie o currículo (PDF, DOCX ou TXT) e clique em **Montar perfil a partir do CV**: a IA
   preenche um rascunho que você revisa antes de salvar. Ajuste a área, os cargos alvo, o nível e as
   skills em três níveis (essencial +30, importante +10, extra +5). Use **Ver prévia** para ver como
   ficam as notas antes de salvar. Sem IA, preencha à mão: a tela sugere cargos e skills da sua área.
2. **Vagas.** A cada 3 horas o agregador busca pelos termos do seu perfil. Na triagem, salve as boas
   (viram candidaturas) e descarte o resto.
3. **Candidaturas.** Mova os cartões no kanban. Se o Gmail estiver ligado, as respostas das empresas
   (recusa, entrevista, teste, proposta) movem os cartões sozinhas. Convites para entrevista assíncrona
   (vídeo ou áudio gravado, entrevista com IA, como HireVue e Willo) vão para a coluna **Entrevista com IA**.
4. **Radar.** O que fazer à mão, por frequência, com as buscas já montadas para o seu perfil. Crie os
   alertas de vaga do LinkedIn pelas buscas da seção **Alertas do LinkedIn**.

## O que tem em cada tela

| Tela | Para que serve |
| - | - |
| **Painel** | Vagas novas por nota, follow-ups do dia, respostas das empresas e a rotina de hoje. |
| **Vagas** | Triagem com filtros e ordenação: salvar, salvar em aplicadas, descartar, analisar com IA, marcar como vaga dos sonhos. |
| **Candidaturas** | Kanban e tabela, e-mails da empresa em cada candidatura, exportação `.xlsx` e CSV. |
| **Métricas** | Candidaturas por semana, funil, taxas de resposta e de entrevista por origem e as fontes que mais rendem. |
| **Radar** | O que fazer à mão: publicações e pessoas no LinkedIn, X, Google, grupos do Telegram, sites sem API e cadastros. |
| **Mensagens** | Modelos de mensagem preenchidos com a vaga, o contato e o seu perfil. |
| **Rotina** | Checklist diário e semanal. |
| **Contatos** e **Empresas-alvo** | Recrutadores e gestores; empresas cujos quadros de vagas o agregador consulta. |
| **Perfil** | Quem você é e o que procura: dele saem a nota, as buscas, o Radar e a IA. |
| **Ajustes** | Chaves e contas, extensão, notificações, descarte automático, fontes e backup. |

As fontes automáticas: Remotive, Remote OK, We Work Remotely, Working Nomads, Himalayas, Remotar,
backend-br e frontendbr (GitHub), Hacker News "Who is hiring", GoRails Jobs e os quadros Greenhouse,
Lever, Ashby e Workable das empresas-alvo. As de nicho só rodam quando combinam com o seu perfil, e
cada uma pode ser desligada em Ajustes. Cada fonte respeita os limites e os créditos que a API pede.

## IA (OpenRouter)

1. Crie a conta em [openrouter.ai](https://openrouter.ai).
2. Gere a chave em [Settings → Keys](https://openrouter.ai/settings/keys) e cole em **Ajustes → Chaves
   e contas** (ou no Primeiro uso). Use **Testar OpenRouter** para conferir.
3. Escolha o modelo em **Ajustes → Chaves e contas → Modelo**:

| | Gratuito (padrão) | Pago |
| - | - | - |
| Modelo | MiniMax M3.1 Flash (`minimax/minimax-m3.1-flash:free`); se ele estiver fora do ar ou no limite, o OpenRouter escolhe outro modelo gratuito (`openrouter/free`) | DeepSeek V4 Pro (`deepseek/deepseek-v4-pro-0813`), ou outro modelo do OpenRouter que você digitar |
| Custo | Nenhum; não precisa de crédito | Centavos de dólar por mês no uso normal; precisa de créditos em [Settings → Credits](https://openrouter.ai/settings/credits) |
| Limites | O OpenRouter limita os pedidos gratuitos por minuto e por dia (o limite diário sobe para quem já comprou créditos). Quando passar, a IA avisa e volta a funcionar mais tarde | Sem limite apertado |
| Seus dados | Os provedores dos modelos gratuitos podem guardar e usar o que você envia (currículo, vagas, e-mails das empresas) para treinar modelos | Seguem a política de cada provedor, que você vê e controla em [Settings → Privacy](https://openrouter.ai/settings/privacy) |

Se o OpenRouter recusar os modelos gratuitos por causa da sua política de dados, libere-os em
[Settings → Privacy](https://openrouter.ai/settings/privacy) ou mude para o pago. Os ids dos modelos
gratuitos mudam com o tempo; por isso o app tem a reserva `openrouter/free`.

A IA só roda quando você clica: montar o perfil, analisar o fit, adaptar o resumo do CV ou escrever uma
mensagem. A exceção é a leitura das respostas das empresas no Gmail, que roda sozinha. No modelo pago, o
botão mostra o custo estimado antes, e cada resultado guarda o custo real. A IA usa só os fatos do seu
perfil e nunca inventa experiência.

## Gmail (alertas do LinkedIn e respostas das empresas)

O WorkMachine entra no Gmail com uma **senha de app**: uma senha de 16 letras, separada da senha da
conta, que o Google gera para um programa só. A senha normal da conta não funciona.

1. Ligue a **verificação em duas etapas** na conta Google: em
   [myaccount.google.com/security](https://myaccount.google.com/security), **Verificação em duas
   etapas** → **Ativar**. Sem ela, o Google não oferece senha de app.
2. Abra [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords) (o Google pode
   pedir a senha da conta de novo), digite o nome "WorkMachine" e clique em **Criar**.
3. Copie as 16 letras que aparecem. Elas são mostradas uma vez só; se perder, apague essa senha e crie
   outra. Os espaços entre os blocos não fazem diferença.
4. Em **Ajustes → Chaves e contas**, informe o e-mail e a senha de app e clique em **Testar Gmail**.
5. No LinkedIn, crie os alertas de vaga (por e-mail, diários) pelas buscas do Radar.

O WorkMachine abre a caixa só para leitura: nada é marcado como lido, movido ou apagado. A cada hora ele
importa os alertas do LinkedIn e procura as respostas das empresas em que você aplicou. Na primeira vez,
ele olha os alertas dos últimos 14 dias e as respostas dos últimos 30.

Problemas comuns:

- **A página de senhas de app diz que a opção não está disponível:** a verificação em duas etapas está
  desligada, a conta é de trabalho ou de escola (o administrador pode ter bloqueado) ou a conta usa a
  Proteção Avançada do Google. Nos dois últimos casos, use outro Gmail para receber os alertas.
- **"Testar Gmail" diz que o Google exige uma senha de app:** foi usada a senha normal da conta. Gere a
  senha de app e cole as 16 letras.
- **Os alertas do LinkedIn não chegam ao app:** se um filtro do Gmail tira os alertas da caixa de
  entrada, o WorkMachine não os vê. Tire o filtro, ou faça o app ler todos os e-mails com a linha
  `GMAIL_MAILBOX=[Gmail]/Todos os e-mails` no `.env` (`[Gmail]/All Mail` se o Gmail estiver em inglês);
  depois rode `docker compose up -d`.
- **Para cortar o acesso:** apague a senha "WorkMachine" em
  [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords). A senha da conta não
  muda, e o app para de ler a caixa na hora.

## Extensão do navegador

Ela salva no WorkMachine a vaga aberta em qualquer site (LinkedIn, Greenhouse, Lever, Gupy, páginas de
carreira…), mostra no ícone a nota das vagas do LinkedIn que já estão no app e salva recrutadores em
Contatos.

1. Em **Ajustes → Extensão do navegador**, clique em **Gerar token** e copie.
2. Abra `chrome://extensions` (ou `edge://extensions`), ligue o **Modo do desenvolvedor** e clique em
   **Carregar sem compactação**. Escolha a pasta `extension` de dentro da pasta do WorkMachine.
   - **Windows com o projeto dentro do WSL:** o Chrome nem sempre abre pastas do WSL. Copie a pasta para
     o Windows e carregue a cópia:
     ```bash
     cp -r extension/. /mnt/c/Users/SEU_USUARIO/WorkMachine-extension/
     ```
3. Fixe o ícone na barra, abra as **Opções** da extensão, cole o token e clique em **Testar conexão**.

Depois de atualizar o WorkMachine, clique em recarregar (↻) no cartão da extensão (no Windows com WSL,
copie a pasta de novo antes). Ajustes mostra a versão esperada. Detalhes em
[extension/README.md](extension/README.md).

## Notificações

Em **Ajustes**, clique em **Ativar notificações** (de preferência dentro do app instalado). Chegam
avisos de vagas novas com nota alta (padrão 40), de respostas das empresas e, às 8h, dos follow-ups do
dia. Cada tipo pode ser desligado.

## Backup e dados

Tudo fica no volume `storage` do Docker: banco, currículo e as chaves que criptografam as senhas.

- **Backup automático:** a cada hora o banco é copiado para a pasta `backups` dentro da pasta do
  WorkMachine. Ficam as cópias das últimas 24 horas e uma por dia dos últimos 14 dias. Para gravar em
  outra pasta (uma que já vai para a nuvem, por exemplo), crie um arquivo `.env` na pasta do
  WorkMachine com a linha `WORKMACHINE_BACKUP_DIR=` e o caminho da pasta (exemplos no
  [DEVELOPMENT.md](DEVELOPMENT.md#variáveis-de-ambiente)); depois rode `docker compose up -d`.
- **Planilha:** Candidaturas → Exportar .xlsx ou Exportar CSV.
- **Restaurar um backup** (troque o nome do arquivo):
  ```bash
  docker compose stop web
  docker compose run --rm --no-deps --entrypoint sh web -c \
    'cp backups/workmachine-AAAA-MM-DD-HHMM.sqlite3 storage/production.sqlite3 && rm -f storage/production.sqlite3-wal storage/production.sqlite3-shm'
  docker compose start web
  ```
  As senhas salvas em Ajustes só abrem com o arquivo `storage/workmachine-secrets.yml` do mesmo volume.
  Num volume novo, informe as chaves de novo em Ajustes.
- **Apagar tudo:** `docker compose down -v` remove o app e o volume com os dados. Os backups ficam.

## Atualizar

```bash
docker compose pull && docker compose up -d
```

O banco é atualizado sozinho ao subir. Quem baixou com git pode rodar `git pull` antes, para receber
também a extensão nova (e recarregá-la no navegador).

## Problemas comuns

- **A porta 3000 já está em uso:** troque `127.0.0.1:3000:3000` por `127.0.0.1:3001:3000` no
  `docker-compose.yml` e abra http://localhost:3001 (nas Opções da extensão, troque o endereço também).
- **Esqueci a senha:**
  ```bash
  docker compose exec web bin/rails runner 'User.first.update!(password: "uma-senha-nova")'
  ```
- **Ver o que está acontecendo:** `docker compose logs -f web`.
- **Buscar vagas agora:** botão **Buscar agora** em Vagas.

## Privacidade

O WorkMachine roda só no seu computador e não manda dados para o autor nem para servidor algum. Saem
dele apenas: as buscas às fontes públicas de vagas; a conexão de leitura com o seu Gmail, se ligada; e,
quando você usa uma função de IA, o texto necessário (currículo, perfil, vaga ou e-mail da empresa) para o
OpenRouter, com a sua chave. As senhas ficam criptografadas no banco local.

## Licença e contribuição

Código aberto sob a [GNU AGPL-3.0](LICENSE): você pode usar, estudar, modificar e distribuir; quem
distribuir ou oferecer pela rede uma versão modificada precisa abrir o código dela sob a mesma licença.

Achou um problema ou tem uma sugestão? Abra uma issue. Quer mexer no código? Veja
[CONTRIBUTING.md](CONTRIBUTING.md) e [DEVELOPMENT.md](DEVELOPMENT.md).
