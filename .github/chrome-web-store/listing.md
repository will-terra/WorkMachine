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
- **Idiomas:** inglês é o padrão (`default_locale` do manifest) e português (Brasil) entra como segundo
  idioma em **Ficha da loja → Idioma**, com a descrição de `descricao-pt-BR.txt`. A extensão mostra português
  quando o Chrome está em pt-BR ou pt-PT e inglês nos outros casos (`extension/_locales/`).
- **Ícone da loja:** `extension/icons/icon-128.png`
- **Capturas:** `captura-1.png` a `captura-5.png`, nesta ordem
- **Bloco promocional pequeno:** `promo-pequeno-440x280.png`
- **Marquee:** `promo-marquee-1400x560.png`
- **Site oficial:** https://github.com/will-terra/WorkMachine
- **Suporte:** https://github.com/will-terra/WorkMachine/issues

**Descrição:** cole o conteúdo de um destes arquivos, inteiro e sem mais nada (a loja mostra texto puro,
não formata Markdown; nunca cole este `listing.md`):

- `description-en.txt`: inglês, o idioma padrão a partir da versão 1.3.0 (`default_locale` do manifest).
- `descricao-pt-BR.txt`: português (Brasil), em **Idioma → Português (Brasil)**.

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

## Publicada

Página na loja: https://chromewebstore.google.com/detail/lohldenjhfbijbcolpglchnnionlbfaa (código `lohldenjhfbijbcolpglchnnionlbfaa`). Os READMEs instalam por ela.

A cada versão nova: suba a `version` do `extension/manifest.json`, rode `bin/rails extension:zip` e envie
o zip em **Pacote → Enviar novo pacote**. A loja revisa e atualiza a extensão de quem já tem.
