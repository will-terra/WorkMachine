# Handoff: WorkMachine · tema escuro Rails + redesign das telas

## Visão geral
Redesign completo da interface do WorkMachine (`will-terra/WorkMachine`):
- **Tema escuro por padrão**, com o vermelho Rails `#c7262f` como cor principal e de destaque.
- **Nova tipografia**: Bricolage Grotesque (títulos), IBM Plex Sans (texto), JetBrains Mono (números, datas, consultas e linhas de status).
- **Identidade Ruby on Rails**: rubi ao lado da marca, selo "on Rails" no cabeçalho, rodapé "Feito com Ruby on Rails".
- **Painel mais enxuto**: Rotina de hoje no topo; a manchete do dia (data + "11 vagas novas…" + parágrafo "Desde ontem…") foi **removida**.
- Layouts para todas as 11 telas: Painel, Vagas, Candidaturas, Métricas, Radar, Mensagens, Rotina, Contatos, Empresas-alvo, Perfil e Ajustes.

## Sobre os arquivos de design
`WorkMachine Redesign v2.dc.html` é uma **referência de design feita em HTML**: um protótipo navegável que mostra aparência e comportamento. **Não é código de produção para copiar.** A tarefa é recriar esse design no app Rails que já existe, com o que ele já usa: **Rails 8.1 + Hotwire (Turbo/Stimulus), importmap, Tailwind v4, views ERB**. Os dados do protótipo são fictícios; no app, tudo vem dos models (`Profile`, `JobPosting`, `JobApplication`, `Radar`, `Setting`…).

Para abrir o protótipo, sirva a pasta por HTTP (ex.: `npx serve .` ou `ruby -run -e httpd . -p 8000`) e abra o `.dc.html`. Ele precisa de `support.js`, de `assets/` e de `_ds/` ao lado. Pelo menu do protótipo dá para navegar por todas as telas.

## Fidelidade
**Alta fidelidade (hifi).** Cores, tipografia, espaçamentos e interações são finais. Recrie fiel ao protótipo, usando as classes de componente do Tailwind do app.

## Como aplicar (ordem sugerida, um commit por passo, com testes passando)
1. `Feat: tema escuro Rails` — substituir `app/assets/tailwind/application.css` por `application.tailwind.css` (deste pacote). Os nomes de token que as views já usam continuam os mesmos (`bg`, `surface`, `ink`, `muted`, `line`, `code`, `accent`, `accent-ink`, `accent-soft`, `ok`, `warn`, `ramp-1..4`); o bloco `prefers-color-scheme` some, porque o escuro passa a ser o padrão. Carregar as fontes no layout:
   ```html
   <link rel="preconnect" href="https://fonts.googleapis.com">
   <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,600;12..96,700&family=IBM+Plex+Sans:ital,wght@0,400;0,500;0,600;1,400&family=JetBrains+Mono:wght@400;600&display=swap">
   ```
   Atenção ao `CLAUDE.md`: o app roda local, mas as fontes vêm do Google Fonts. Se preferir zero rede, baixe os `.woff2` para `app/assets/fonts` e use `@font-face`.
2. `Feat: cabeçalho e rodapé Rails` — `app/views/layouts/application.html.erb`: o rubi (`assets/ruby.png` → `app/assets/images/ruby.png`), o selo "on Rails", a navegação e o rodapé.
3. `Feat: painel enxuto` — `dashboard/show`.
4. As demais telas, uma por commit.
5. Atualizar os request specs que checam textos removidos (ex.: a manchete do Painel).

## Tokens de design

### Cores
| Token | Hex | Uso |
| - | - | - |
| bg | `#121010` | fundo da página |
| surface | `#1d1a19` | cartões, item selecionado na lista, caixa da prévia de mensagem, toast |
| ink | `#ece6e3` | texto |
| muted | `#9b9593` (ink a 64%) | texto secundário, metadados |
| line | `#2f2b2a` (ink a 13%) | hairlines, bordas de botão secundário e de campo |
| code | `#2c2726` | chips neutros |
| field | `#3a3433` | trilho da barra de progresso |
| switch-off | `#524b49` | switch desligado |
| **accent** | **`#c7262f`** | botão primário, opção marcada do seletor, aba ativa + contagem, **links**, nota ≥ 60, número grande da melhor vaga, switch ligado, checkbox marcado, barras |
| accent-hover | `#f05a5f` | hover de botão primário e de link |
| accent-ink | `#ffffff` | texto sobre o vermelho: **sempre branco**, inclusive no hover e no estado pressionado |
| accent-soft | `#2a1214` | fundo de tag vermelha, selo "on Rails", coluna do kanban ao arrastar por cima |
| accent-text | `#ffa3a3` | texto sobre accent-soft |
| warn | `#f0ad3a` | segundo acento (âmbar), usado com moderação |
| warn-soft | `#2a1f0c` | fundo de tag âmbar (recusa, follow-up vencido, nota parcial, termo negativo) |
| warn-text | `#fad590` | texto sobre warn-soft |
| warn-strong | `#f5c060` | pontos negativos, "com erro", contador acima do limite |
| ramp-1..4 | `#5a1a20` `#c7262f` `#ff7a7c` `#ffd0cf` | barras do funil (Aplicadas → Proposta) |

**Faixas de nota:** ≥ 60 `accent #c7262f` · 35–59 `ink` · < 35 `muted`.

### Tipografia
- Títulos: **Bricolage Grotesque**, 600 (marca e número grande: 700). H1 de página 44px/1.12, letter-spacing −0.03em; H2 de seção 20px (22px no Radar, 24px no detalhe de modelo); H3 15px.
- Texto: **IBM Plex Sans**, 400/500/600. Base 15px/1.55; listas 14–15px; metadados 13–13.5px.
- Mono: **JetBrains Mono** 400/600. Notas nas listas (17px no Painel, 26px em Vagas), datas, contagens da navegação (11.5px), linhas de status (11.5–12px), consultas do Radar (12.5px), token, IDs de modelo, kicker das páginas (12px, minúsculo, muted).
- Botões e opções de seletor usam a fonte de título, 14px/600 (13px nos compactos), com `white-space: nowrap`.

### Espaçamento, raio e sombra
- Largura máxima 1280px; padding lateral `clamp(20px, 4vw, 56px)`.
- Cabeçalho de página: `padding: 48px 0 28px` (Painel começa em 32px).
- Raio: 2px (botão, campo, tag ~1.5px), 4px (cartão, coluna do kanban, toast). Não usar `rounded-xl`.
- Sombras no escuro: hairline + escuridão (`0 0 0 1px ink/10%, 0 6px 18px #000a` para o toast).
- Separação de seções: espaço em branco; hairlines `line` só em listas, tabelas, na faixa de status e entre seções de Ajustes.

## Telas

### Cabeçalho (todas)
- Linha 1: à esquerda, rubi 26×26 + "WorkMachine" (Bricolage 700, 24px, −0.03em) + selo `on Rails` (mono 11px, padding 3×7, fundo accent-soft, texto accent-text). À direita, Perfil · Ajustes (14px; ficam em accent quando ativos) · botão ghost "Sair".
- Linha 2 (padding-top 16px): navegação em flex-wrap, gap 6×22px, 14.5px. Aba ativa: `accent`, 600. Contagem de vagas novas ao lado de "Vagas": mono 11.5px/600, accent.
- Rodapé: mono 12px muted, flex gap 16px: rubi 16px + "Feito com Ruby on Rails" (ink) · "WorkMachine 0.9" · licença AGPL-3.0 · código-fonte.

### Painel (`dashboard/show`)
Em ordem:
1. **Rotina de hoje** (H1 24px) + à direita uma barra de progresso (96×4, trilho `field`, preenchimento accent), "3/13 feitos" em mono 12px e o link "Ver regras". Grade `repeat(auto-fit, minmax(230px,1fr))`, gap 20×36. Cada horário: H3 15px + duração em mono 11.5 muted; itens como checkbox de 14px (marcado: fundo accent com ✓ na cor do fundo) e texto 13.5/1.4; item feito fica muted e riscado. Os itens vêm de `config/routine.yml` e o clique faz `POST rotina/itens/:key` (Turbo).
2. **Faixa de status** (margin-top 32, padding 12×0, hairlines em cima e embaixo): à esquerda, os status em andamento como "Salva **2**", com a contagem em mono 13/600 (accent quando > 0, muted quando 0); à direita, em mono 11.5 muted: "N candidaturas em andamento · busca 12:00 → 15:00 · Gmail 12:40".
3. Duas colunas (flex 7/5, wrap, gap 40×clamp(36px,5vw,80px), padding-top 32):
   - **Vagas novas por nota** (H2 20px + link "11 para triar →"). Melhor vaga: número de 60px em accent, kicker mono, título 21px, metadados 14px muted, uma linha com Salvar (primário) · Descartar · Ler a vaga e as tags de termos. Depois, até 5 linhas: nota mono 17px (cor da faixa) + título 15/500 + metadados 13px; padding 7px.
   - Coluna lateral, gap 36: **Follow-ups do dia** (empresa 15/600, cargo · quando em 13 muted, botões compactos Follow-up/Editar) e **Respostas das empresas** (tag da categoria + empresa + mono "20/10 14:32 · de → **para**" + resumo em 14px).
- **Removido:** a data, as duas manchetes, o parágrafo "Desde ontem…" e os botões "Começar a triagem"/"Ver candidaturas".

### Vagas (`job_postings/index` + `show`)
Mantém a estrutura atual: lista e detalhe lado a lado (flex 5/7, o detalhe é sticky). Filtros: seletores de Triagem e Ordenar, selects de Nota mínima, Região e Senioridade, campo Buscar. Atalhos: ↑/↓ (ou j/k) navegam, S salva, A salva em aplicadas, D descarta; ficam desligados quando o foco está num campo. Item selecionado com fundo `surface`. Detalhe: kicker mono, título clamp(26–34px), ações, nota de 72px (cor da faixa) + "/ 100", composição da nota com linha pontilhada, `dl` de fatos e a descrição. Salvar, aplicar ou descartar mostra um toast embaixo à esquerda com **Desfazer** (6s).

### Candidaturas (`job_applications/index`)
Seletor Kanban/Tabela + Verificar respostas · Exportar .xlsx · Nova candidatura. Kanban: colunas de 252px com scroll horizontal; cartões `.card` (empresa em Bricolage 16/600, cargo 13.5 muted, chips de origem, "↗ 08/10" e "follow-up 22/10", este em âmbar quando vencido), links Editar · Mensagem · Abrir vaga em accent. Coluna recebendo um cartão arrastado: fundo accent-soft. O arrastar já existe em `kanban_controller.js`; manter `PATCH move`.

### Métricas (`metrics/show`)
Seletor de período (30 dias · 90 dias · Tudo), 4 números (58px Bricolage), barras semanais em accent, funil com ramp-1..4 e duas tabelas (por origem; fontes de vagas ordenadas por aproveitamento).

### Radar (`radar/show`, `config/radar.yml`)
- Cabeçalho + seletor de **frequência** (Todo dia · Toda semana · Uma vez) que filtra as tarefas por `cadence`.
- Faixa "O WorkMachine consulta 13 fontes sozinho: 11 ok · 1 com erro · 1 desligada" (a parte de erro em warn-strong, mono) + botão "Ver fontes", que abre a tabela de `automated`: fonte + nota, última execução (`SourceRun`), lidas, novas e situação (tag: ok neutra, falhou âmbar com a mensagem de erro, desligada com contorno).
- Abaixo do seletor, o tempo da frequência em mono muted (ex.: "~15 min, depois de triar as vagas novas").
- Cada tarefa: H2 22px + ação (14.5px, máx. 72ch); à direita, os filtros da tarefa como seletores (`li_region`, `li_period`, `post_period`, `g_period`). `status` vira uma tag accent-soft + texto muted.
- Buscas: linhas com hairline em cima; título (14rem, 500, nota opcional), consulta já preenchida (mono 12.5, neutra clara, quebra em qualquer ponto), botões **Copiar** (vira "Copiado" por 1.6s; `clipboard_controller.js`) e **Abrir ↗** (secundário, nova aba; URL de `Radar.url_for` com os filtros escolhidos).
- Links (Telegram, Sites sem API): botões secundários com ↗; a nota vai no `title`. Entram só os `only_for` que combinam com o perfil.
- Cadastros: três grupos (Plataformas, Consultorias tech, Multinacionais) com contagem "2/7"; checkbox + nome (link) + nota; o item marcado fica riscado e muted (`PATCH consultancies/:id`).

### Mensagens (`message_templates/index`)
- Lista de modelos à esquerda (flex 3): nome 14.5/500, "até 200" e o idioma (PT/EN) em mono muted; o selecionado tem fundo surface.
- Detalhe (flex 7): nome do modelo (24px) + select "Preencher com uma candidatura" (preenche cargo e empresa); campos Nome, Cargo e Empresa; **prévia** numa caixa surface (15.5/1.65, `pre-wrap`): o que foi preenchido aparece em accent-text; placeholder vazio (`{{nome}}`…) aparece com fundo âmbar (warn-soft mais forte, `#3d2c0f`) e texto warn-text. `{{meu_resumo}}`/`{{minha_stack}}` vêm de `MessageTemplate.profile_values`. Contador "143 / 200 caracteres" em mono, warn-strong quando passa de `max_chars`. Botões "Editar modelo" (abre um textarea mono com o corpo cru) e **Copiar mensagem**.
- Entrada pelo Contatos → Mensagem: abre com o nome (primeiro nome) e a empresa preenchidos (recrutador → "Conexão com recrutador", gestor → "Achei a vaga no post"). Use `message_controller.js`.

### Rotina (`routines/show`)
Cabeçalho com barra de progresso de 140×5 + contagem. Grade `minmax(340px,1fr)`: H2 20px + duração; checkboxes maiores (texto 15/1.5). Abaixo, **Regras** (`rules` do yml): lista numerada 01–04 com o número em mono accent, título em 600 e o texto.

### Contatos (`contacts/index`)
Seletor Tipo (Todos · Recrutadores · Gestores) + Buscar (nome, empresa). Tabela: Nome (600) com o headline embaixo (12.5 muted) · Empresa · Tipo (tag: recrutador neutra, gestor accent-soft) · Último contato (mono; "há N dias" e muted quando passa de 30 dias; "nunca" quando vazio) · ações ghost: LinkedIn ↗ · Mensagem · Editar.

### Empresas-alvo (`target_companies/index`)
- No cabeçalho: campo "Procurar o quadro de uma empresa" + Procurar (`POST find`) + Adicionar.
- **Sugeridas** (`TargetCompany.suggested`): grade de `.card` com nome (Bricolage 17), "ats · slug" em mono, a vaga de origem e os botões Ativar (primário, `POST activate`) e Dispensar (`POST dismiss`).
- **Quadros consultados**: tabela com Empresa (+ tag "exemplo" quando `example`) · Quadro (link mono `ats/slug` → `board_url`) · Vagas · Salvas · Auto-descartadas (`posting_stats`) · Última leitura · Ativa (switch). Linha inativa com opacidade 0.55.

### Perfil (`profiles/show`)
- Cabeçalho: "Montar perfil a partir do CV" + **Salvar perfil**.
- Coluna principal (flex 7), seções com gap 40:
  1. **Skills**: linhas Essencial **+30**, Importante **+10**, Extra **+5** e Evitar **−15** (pontos em mono; accent, ou warn-strong em Evitar). Chips com botão × (essencial: `#3d1519`/`#ffd0cf`; importante e extra: code/ink; evitar: warn-soft/warn-text) e um campo "adicionar…" de 130px que adiciona com Enter. Sinônimos podem ficar num popover do chip (fora do protótipo).
  2. **O que procura**: Área principal, Plano B, Anos de experiência, Cargos alvo (PT/EN); seletor de Nível (Júnior · Pleno · Sênior); chips de Modo de trabalho e Regiões aceitas (ligado: fundo accent-soft, borda `#8a1f27`, texto accent-text; desligado: transparente, borda line, texto muted); pretensão R$ e US$ (mín./máx.).
  3. **Quem você é**: nome, título, local, fuso, idiomas, LinkedIn, GitHub, portfólio.
  4. **Currículo**: nome do arquivo em mono + data, "Trocar arquivo", "Ver texto extraído" e a nota sobre formatos.
- Coluna lateral sticky (flex 4): **Prévia das notas**: colunas vaga | agora | prévia; "prévia" em mono 600 com a diferença embaixo (+ em accent, − em warn-strong). A frase-resumo diz quantas vagas mudam. No app, ligue a `POST/PATCH perfil/preview` (`ProfilePreview`) com debounce pelo `profile_form_controller.js`. Ao salvar: toast "Perfil salvo. N vagas foram recalculadas." (o `RescorePostingsJob` já roda).

### Ajustes (`settings/show`)
Cada seção é uma linha (hairline em cima, padding 28×0): à esquerda, título 19px + explicação 13.5 muted (até 320px); à direita, os controles.
- **Chaves e contas**: chave do OpenRouter (password, mono) + Testar OpenRouter → "✓ conectado · MiniMax M3.1 Flash" (mono, accent-text). Seletor Gratuito/Pago + id do modelo em mono + nota sobre custo e uso dos dados. Gmail + senha de app + Testar Gmail → "✓ caixa aberta só para leitura · última leitura…".
- **Extensão do navegador**: token numa caixa mono surface (mostra os 6 primeiros caracteres e depois •), botões Mostrar/Esconder · Copiar · Gerar outro; versão esperada.
- **Notificações**: switches (Ativar notificações, Respostas das empresas, Follow-ups do dia) + "Avisar vagas com nota a partir de" (número) + "Enviar notificação de teste".
- **Descarte automático**: switches (restritas a outros países; ler as respostas das empresas) + select "Descartar vagas com nota abaixo de".
- **Fontes**: grade de checkboxes, `minmax(210px,1fr)` (`enabled_sources`).
- **Backup**: "último backup: hoje, 12:00 · backups/" em mono + "Fazer backup agora" (`POST backup`).
- Switch: 36×20, raio cheio, knob de 16px na cor ink; ligado em accent, desligado em switch-off; transição de 150ms.

## Interações e estados
- Hover: botão primário fica `#f05a5f` com texto branco; secundário e ghost ganham fundo ink a 7%; link fica accent-hover.
- Foco: `outline: 2px solid #c7262f; outline-offset: 2px` (nunca o anel azul padrão).
- Desabilitado: opacidade 0.45.
- Toast com Desfazer, 6s (triagem e salvar perfil).
- Botões de copiar trocam o texto para "Copiado" por 1.6s.
- Responsivo: tudo em flex-wrap/auto-fit; nada de largura fixa em caixa com texto; o kanban rola na horizontal.

## Assets
- `assets/ruby.png`: logo oficial do Ruby (PNG com transparência, 1280×1277), mandado pelo usuário. Usado com 26px no cabeçalho e 16px no rodapé.
- Ícones: o protótipo quase não usa ícones (✓ do checkbox e a faísca de "Analisar com IA", do Phosphor). Use o set que o app já tiver.

## Arquivos deste pacote
- `README.md`: este documento.
- `application.tailwind.css`: proposta pronta para `app/assets/tailwind/application.css`.
- `WorkMachine Redesign v2.dc.html`: protótipo de referência (abrir por HTTP).
- `support.js`, `_ds/…`: runtime e estilos base do protótipo, só para ele abrir. **Não levar para o app.**
- `assets/ruby.png`.
