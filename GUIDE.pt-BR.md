# Guia de uso do WorkMachine

[English](GUIDE.md) · **Português (Brasil)**

Os detalhes que o [README](README.pt-BR.md) resume. Para instalar, veja [Instalar](README.pt-BR.md#instalar).

[Primeiros passos](#primeiros-passos) · [Telas](#telas) · [Fontes automáticas](#fontes-automáticas) ·
[IA](#ia-openrouter) · [Gmail](#gmail) · [Extensão](#extensão-do-navegador) ·
[Notificações](#notificações) · [Backup e dados](#backup-e-dados) · [Problemas comuns](#problemas-comuns)

## Primeiros passos

O app abre com a rotina **Configuração do app**: um passo a passo com link para cada tela. Em resumo:

1. **Perfil.** Envie o currículo (PDF, DOCX ou TXT) e clique em **Montar perfil a partir do CV**: a IA
   preenche um rascunho que você revisa antes de salvar. Ajuste a área, os cargos alvo, o nível e as
   skills em três níveis. A prévia ao lado mostra como ficam as notas. Sem IA, preencha à mão: a tela
   sugere cargos e skills da sua área.
2. **Vagas.** A cada 3 horas o agregador busca pelos termos do seu perfil. Na triagem, salve as boas
   (viram candidaturas) e descarte o resto.
3. **Candidaturas.** Mova os cartões no kanban. Se o Gmail estiver ligado, as respostas das empresas
   (recusa, entrevista, teste, proposta) movem os cartões sozinhas. Convites para entrevista assíncrona
   (vídeo ou áudio gravado, entrevista com IA, como HireVue e Willo) vão para a coluna **Entrevista com IA**.
4. **Radar.** O que fazer à mão, por frequência, com as buscas já montadas para o seu perfil. Crie os
   alertas de vaga do LinkedIn pelas buscas da seção **Alertas do LinkedIn** e marque cada um como
   ativado: quando o perfil mudar, os alertas novos aparecem ali.

## Telas

| Tela | Para que serve |
| - | - |
| **Painel** | Rotina de hoje, vagas novas por nota, follow-ups do dia e respostas das empresas. |
| **Vagas** | Triagem com filtros e ordenação: salvar, salvar em aplicadas, descartar, analisar com IA, marcar como vaga dos sonhos. Atalhos: `S` salva, `A` salva em aplicadas, `D` descarta. |
| **Candidaturas** | Kanban e tabela, e-mails da empresa em cada candidatura, exportação `.xlsx` e CSV. |
| **Rotina** | Checklist diário e semanal e o passo a passo de configuração do app. As rotinas são editadas em **Ajustes → Rotinas**. |
| **Radar** | O que fazer à mão: alertas do LinkedIn para ativar, publicações e pessoas no LinkedIn, X, Google, grupos do Telegram, sites sem API e cadastros. |
| **Contatos** e **Empresas-alvo** | Recrutadores e gestores; empresas cujos quadros de vagas o agregador consulta. |
| **Mensagens** | Modelos de mensagem preenchidos com a vaga, o contato e o seu perfil, com contador de caracteres para a nota de conexão do LinkedIn. |
| **Métricas** | Candidaturas por semana, funil, taxas de resposta e de entrevista por origem e as fontes que mais rendem. |
| **Perfil** | Quem você é e o que procura: dele saem a nota, as buscas, o Radar e a IA. |
| **Ajustes** | Idioma, chaves e contas, extensão, notificações, descarte automático, fontes, rotinas e backup. |

A interface segue o idioma do navegador (português para pt-BR e pt-PT, inglês para o resto), e você pode
escolher em **Ajustes → Idioma**.

## Fontes automáticas

Remotive, Remote OK, We Work Remotely, Working Nomads, Himalayas, Remotar, Gupy, Programathor, Vagas.com,
canais do Telegram (para perfil júnior), backend-br e frontendbr (GitHub), Hacker News "Who is hiring",
GoRails Jobs e os quadros Greenhouse, Lever, Ashby e Workable das empresas-alvo, além dos seus alertas do
LinkedIn pelo Gmail. As de nicho só rodam quando combinam com o seu perfil, e cada uma pode ser desligada
em Ajustes. Cada fonte respeita os limites e os créditos que a API pede e o que o robots.txt de cada site
permite.

O WorkMachine **não raspa o LinkedIn e não se candidata sozinho**: isso viola os termos do LinkedIn e
arrisca a sua conta. Os alertas de vaga chegam pelo seu Gmail, e a extensão do navegador só lê uma página
quando você clica nela.

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
botão mostra o custo estimado antes, e cada resultado guarda o custo real. Montar o perfil pelo currículo
custa menos de 1 centavo de dólar. A IA usa só os fatos do seu perfil e nunca inventa experiência.

## Gmail

O WorkMachine lê no Gmail os alertas do LinkedIn e as respostas das empresas. Ele entra com uma **senha
de app**: uma senha de 16 letras, separada da senha da conta, que o Google gera para um programa só. A
senha normal da conta não funciona.

1. Ligue a **verificação em duas etapas** na conta Google: em
   [myaccount.google.com/security](https://myaccount.google.com/security), **Verificação em duas
   etapas** → **Ativar**. Sem ela, o Google não oferece senha de app.
2. Abra [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords) (o Google pode
   pedir a senha da conta de novo), digite o nome "WorkMachine" e clique em **Criar**.
3. Copie as 16 letras que aparecem. Elas são mostradas uma vez só; se perder, apague essa senha e crie
   outra. Os espaços entre os blocos não fazem diferença.
4. Em **Ajustes → Chaves e contas**, informe o e-mail e a senha de app e clique em **Testar Gmail**.
5. No LinkedIn, crie os alertas de vaga (por e-mail, diários) pelas buscas do Radar (**Uma vez → Alertas
   do LinkedIn**) e marque cada um como ativado.

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

1. Instale pela **[Chrome Web Store](https://chromewebstore.google.com/detail/lohldenjhfbijbcolpglchnnionlbfaa)**. Funciona no Chrome e no Edge (no Edge, permita
   extensões de outras lojas quando ele perguntar).
2. Em **Ajustes → Extensão do navegador**, clique em **Gerar token** e copie.
3. Fixe o ícone na barra, abra as **Opções** da extensão, cole o token e clique em **Testar conexão**.

Pronto: a loja mantém a extensão atualizada sozinha.

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

## Problemas comuns

- **A porta 3000 já está em uso:** troque `127.0.0.1:3000:3000` por `127.0.0.1:3001:3000` no
  `docker-compose.yml` e abra http://localhost:3001 (nas Opções da extensão, troque o endereço também).
- **Esqueci a senha:**
  ```bash
  docker compose exec web bin/rails runner 'User.first.update!(password: "uma-senha-nova")'
  ```
- **Ver o que está acontecendo:** `docker compose logs -f web`.
- **Buscar vagas agora:** botão **Buscar agora** em Vagas.
- **Problemas com o Gmail:** veja [Gmail](#gmail).
