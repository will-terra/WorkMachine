# Extensão WorkMachine (Chrome / Edge)

Botão **Salvar no WorkMachine** para a vaga aberta no navegador. A extensão só lê a página
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
   No Windows com WSL2, a pasta fica em `\\wsl$\Ubuntu\home\<seu-usuário>\WorkMachine\extension`
   (ou copie a pasta para o Windows e carregue a cópia).
5. Fixe o ícone na barra. Clique com o botão direito no ícone → **Opções**, cole o token e use
   **Testar conexão**.

## Como usar

Abra a vaga (LinkedIn, Greenhouse, Lever, Ashby, Gupy, página de carreiras…), clique no ícone,
confira título, empresa e local e clique em **Salvar no WorkMachine**. Marque **Também criar
candidatura** para ela já entrar no kanban como "Salva". O popup mostra a nota da vaga e um link
para abri-la no WorkMachine.

No LinkedIn funciona em `/jobs/view/...` e em `/jobs/search/...` com uma vaga selecionada.
Se a vaga já tinha chegado pelo alerta do Gmail, ela não duplica: a extensão completa a descrição
que o e-mail não traz e a nota é recalculada.

## Como a página é lida

1. JSON-LD `schema.org/JobPosting` (Lever, Ashby, Gupy e muitas páginas de carreira publicam);
2. no LinkedIn, os seletores do cartão da vaga;
3. páginas conhecidas de ATS (Greenhouse, Lever) e um bloco genérico de descrição;
4. tags Open Graph;
5. o título da aba (`document.title`).

Os seletores do LinkedIn mudam de tempos em tempos. Se algum campo vier vazio, preencha no popup
antes de salvar e ajuste os seletores em `extract.js`.

## Arquivos

- `manifest.json`: Manifest V3, permissões `activeTab`, `scripting` e `storage`, e acesso só a
  `http://localhost:3000` e `http://127.0.0.1:3000`.
- `popup.html` / `popup.js`: lê a aba ativa e mostra o formulário.
- `extract.js`: função injetada na página para ler a vaga.
- `service-worker.js`: faz o `POST /api/v1/job_postings` com `Authorization: Bearer <token>`.
  Como a requisição sai da extensão, o Rails não precisa de CORS.
- `options.html` / `options.js`: endereço do servidor e token.
