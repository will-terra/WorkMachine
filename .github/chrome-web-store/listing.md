# Chrome Web Store: ficha da extensão

Textos e imagens para publicar e atualizar a extensão no
[painel do desenvolvedor](https://chrome.google.com/webstore/devconsole). As imagens desta pasta seguem os
tamanhos da loja (capturas 1280×800, bloco promocional 440×280, marquee 1400×560).

## Pacote

```bash
bin/rails extension:zip   # tmp/workmachine-extension-<versão>.zip, com o manifest.json na raiz
```

A cada atualização, suba a `version` do `extension/manifest.json` antes de gerar o zip: a loja recusa um
pacote com a mesma versão do que já está publicado.

## Ficha da loja

- **Nome:** WorkMachine (vem do manifest)
- **Resumo:** vem do `description` do manifest (até 132 caracteres)
- **Categoria:** Produtividade → Fluxo de trabalho e planejamento
- **Idioma:** Português (Brasil)
- **Ícone da loja:** `extension/icons/icon-128.png`
- **Capturas:** `captura-1.png` a `captura-5.png`, nesta ordem
- **Bloco promocional pequeno:** `promo-pequeno-440x280.png`
- **Marquee:** `promo-marquee-1400x560.png`
- **Site oficial:** https://github.com/will-terra/WorkMachine
- **Suporte:** https://github.com/will-terra/WorkMachine/issues

**Descrição:**

```text
A extensão do WorkMachine, o app gratuito e de código aberto de busca de emprego para quem é de tecnologia, que roda no seu próprio computador.

Com um clique no ícone:
• Salve a vaga aberta (LinkedIn, Greenhouse, Lever, Ashby, Gupy, páginas de carreira…) direto na triagem do WorkMachine, que dá uma nota de 0 a 100 pelo seu perfil e explica a conta.
• Salve em aplicadas: a candidatura entra no kanban com a data de hoje.
• Salve recrutadores e gestores em Contatos, a partir do perfil deles no LinkedIn ou da equipe de contratação da vaga. A mensagem para eles já abre preenchida no app.
• Nas vagas do LinkedIn que já estão no WorkMachine, o ícone mostra a nota, e o popup diz se você já aplicou.

Privacidade:
• A extensão só lê a página quando você clica no ícone.
• Ela fala apenas com o WorkMachine que roda no seu computador (localhost:3000). Não há servidor, analytics ou anúncios.
• Ela nunca navega, nunca clica e nunca se candidata sozinha.

Precisa do WorkMachine instalado (Docker, Windows, macOS ou Linux). Instalação em 5 minutos: https://github.com/will-terra/WorkMachine

Depois de instalar: no WorkMachine, abra Ajustes → Extensão do navegador, gere o token e cole nas Opções da extensão.
```

## Privacidade

**Descrição do propósito único:**

```text
Salvar no WorkMachine (o app de busca de emprego que roda no computador da pessoa) as vagas e os recrutadores das páginas que ela abre, e mostrar no ícone a nota das vagas que já estão salvas.
```

**Justificativa das permissões:**

| Permissão | Justificativa |
| - | - |
| `activeTab` | Ler a vaga ou o perfil da aba aberta somente quando a pessoa clica no ícone da extensão, para preencher o formulário de salvar. |
| `scripting` | Executar, na aba ativa e somente depois do clique no ícone, a função que extrai título, empresa, local e descrição da vaga (ou nome, cargo e empresa do perfil). Nenhum script fica injetado nas páginas. |
| `storage` | Guardar localmente o endereço do WorkMachine da pessoa (padrão localhost:3000) e o token de acesso dele, digitados na página de Opções. |
| Permissões de host: `localhost:3000` e `127.0.0.1:3000` | Enviar as vagas e os contatos salvos para o WorkMachine que roda no computador da própria pessoa. Não há outro servidor. |
| Permissões de host: `*.linkedin.com` | Nas páginas de vaga do LinkedIn, ler o endereço da aba para perguntar ao WorkMachine local se a vaga já está salva e mostrar a nota no ícone. O conteúdo da página só é lido quando a pessoa clica no ícone. |

**Código remoto:** Não, não uso código remoto. Todo o JavaScript está no pacote.

**Uso de dados.** Marque os tipos abaixo (os dados vão só para o WorkMachine no computador da própria
pessoa, nunca para terceiros):

- **Informações de identificação pessoal:** nome, cargo e empresa de recrutadores salvos em Contatos.
- **Conteúdo do site:** título, empresa, local e descrição da vaga salva.
- **Histórico da Web:** o endereço das páginas de vaga do LinkedIn, usado para mostrar a nota no ícone.
- **Informações de autenticação:** o token de acesso ao WorkMachine local, guardado na extensão.

E marque as três declarações: não vendo nem transfiro dados a terceiros fora dos casos permitidos; não
uso nem transfiro dados para fins não relacionados ao propósito único; não uso nem transfiro dados para
avaliar crédito ou conceder empréstimos.

**Política de privacidade:** https://github.com/will-terra/WorkMachine/blob/main/PRIVACY.md

## Distribuição

- **Preço:** gratuito
- **Visibilidade:** pública
- **Regiões:** todas

## Conta (uma vez só)

- Confirme o e-mail de contato em **Conta** (sem isso não dá para publicar).
- Na declaração de comerciante (exigida pela União Europeia), escolha **não comerciante**: a extensão é
  gratuita e não vende nada.

## Depois da aprovação

Troque, no README e no `extension/README.md`, o passo de "Carregar sem compactação" pelo link da loja.
A loja atualiza a extensão sozinha a cada versão publicada.
