# Extensão WorkMachine (Chrome / Edge)

Salva no WorkMachine a vaga aberta no navegador e os recrutadores do LinkedIn, e mostra no ícone a
nota das vagas do LinkedIn que já estão no WorkMachine. A extensão só lê o conteúdo da página
quando você clica no ícone dela; ela nunca navega, nunca abre vagas sozinha e nunca se candidata.

## Como instalar

1. No WorkMachine, gere um token e coloque no `.env` (depois reinicie o app):
   ```bash
   bin/rails secret   # copie o valor
   # .env
   WORKMACHINE_API_TOKEN=<o valor copiado>
   ```
2. Abra `chrome://extensions` (Chrome) ou `edge://extensions` (Edge).
3. Ligue o **Modo do desenvolvedor**.
4. Clique em **Carregar sem compactação** e escolha esta pasta `extension/`.
   No Windows com WSL2, o Chrome e o Edge nem sempre carregam extensões de `\\wsl$`; copie a pasta
   para o Windows e carregue a cópia:
   `cp -r ~/WorkMachine/extension/. /mnt/c/Users/$USER/WorkMachine-extension/`.
5. Fixe o ícone na barra. Clique com o botão direito no ícone → **Opções**, cole o token e use
   **Testar conexão**.

Para atualizar, copie a pasta de novo e clique em recarregar (↻) no cartão da extensão.

## Como usar

### Vagas

Abra a vaga (LinkedIn, Greenhouse, Lever, Ashby, Gupy, página de carreiras…), clique no ícone,
confira título, empresa e local e clique em:

- **Salvar no WorkMachine**: a vaga entra na triagem. Marque **Também criar candidatura** para ela
  já entrar no kanban como "Salva".
- **Salvar em aplicadas**: a candidatura vai direto para "Aplicada", com a data de hoje.

Se a vaga já está no WorkMachine (pelo link ou pela mesma empresa e título), o popup mostra a nota, a
triagem ou a candidatura e o link para abri-la. Os botões mudam conforme o caso: **Atualizar no
WorkMachine** completa a descrição que faltava (as vagas dos alertas do Gmail chegam sem descrição e
com nota parcial) e **Marcar como aplicada** move uma candidatura que estava só salva.

No LinkedIn funciona em `/jobs/view/...` e em `/jobs/search/...` com uma vaga selecionada.

### Nota no ícone (LinkedIn)

Enquanto você navega pelas vagas do LinkedIn, o ícone mostra a nota da vaga aberta quando ela já
está no WorkMachine:

- **verde**: você já aplicou (a dica do ícone diz o status da candidatura);
- **vermelho**: está na triagem ou salva, ainda sem aplicar;
- **cinza**: foi descartada (à mão ou pelo descarte automático).

Sem número, a vaga ainda não está no WorkMachine. Para isso a extensão usa só o endereço da aba, que
ela vê graças à permissão para `linkedin.com`; ela não lê nem muda a página e não fala com o LinkedIn,
só com o seu WorkMachine.

### Contatos

- **Na vaga do LinkedIn**: se a vaga tiver "Conheça a equipe de contratação" (Meet the hiring team),
  o popup lista as pessoas com nome, cargo e tipo (recrutador ou gestor, adivinhado pelo cargo).
  **Salvar contato** grava a pessoa em Contatos com a empresa da vaga e uma nota com o link da vaga;
  se a vaga já tiver candidatura sem contato, ela recebe o nome da pessoa (usado em `{{nome}}` nas
  Mensagens).
- **No perfil de alguém** (`linkedin.com/in/...`): o popup mostra nome, cargo e empresa atual para
  salvar em Contatos.

A mesma pessoa salva de novo não duplica: o WorkMachine só preenche o que estiver vazio, então o que
você editou lá fica como está.

## Como a página é lida

1. JSON-LD `schema.org/JobPosting` (Lever, Ashby, Gupy e muitas páginas de carreira publicam);
2. no LinkedIn, os seletores do cartão da vaga e da equipe de contratação;
3. páginas conhecidas de ATS (Greenhouse, Lever) e um bloco genérico de descrição;
4. tags Open Graph;
5. o título da aba (`document.title`).

Os seletores do LinkedIn mudam de tempos em tempos. Se algum campo vier vazio, preencha no popup
antes de salvar e ajuste os seletores em `extract.js`.

## Arquivos

- `manifest.json`: Manifest V3, permissões `activeTab`, `scripting` e `storage`, acesso a
  `http://localhost:3000` e `http://127.0.0.1:3000` e a `linkedin.com` (só para ver o endereço da aba).
- `popup.html` / `popup.js`: lê a aba ativa e mostra o formulário da vaga ou do contato.
- `extract.js`: funções injetadas na página, quando você clica, para ler a vaga e o perfil.
- `service-worker.js`: fala com a API do WorkMachine (`Authorization: Bearer <token>`) e mantém a
  nota no ícone. Como a requisição sai da extensão, o Rails não precisa de CORS.
- `options.html` / `options.js`: endereço do servidor e token.

## API usada

| Rota | Para quê |
| - | - |
| `GET /api/v1/ping` | Testar a conexão nas Opções. |
| `GET /api/v1/job_postings/lookup?url=&company=&title=` | Se a vaga já está no WorkMachine, com nota, triagem e candidatura. |
| `POST /api/v1/job_postings` | Salvar a vaga; `application_status` `saved` ou `applied` cria ou move a candidatura. |
| `GET /api/v1/contacts/lookup?linkedin_url=` | Se a pessoa já está em Contatos. |
| `POST /api/v1/contacts` | Salvar a pessoa (`contact`) e, da equipe de contratação, a vaga (`job`). |
