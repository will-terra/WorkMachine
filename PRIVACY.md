# Política de privacidade

*English version below.*

Última atualização: 22 de outubro de 2026.

O WorkMachine é um app de busca de emprego que roda no seu próprio computador, e a extensão do
navegador é a ponte entre as páginas que você visita e esse app. Não existe servidor do WorkMachine:
nem o autor nem ninguém recebe os seus dados.

## Extensão do navegador

**O que a extensão lê**

- **Quando você clica no ícone**, numa página de vaga: título, empresa, local, endereço e descrição da
  vaga e, nas vagas do LinkedIn, os nomes e cargos da equipe de contratação que aparecem na página.
- **Quando você clica no ícone**, num perfil do LinkedIn: nome, cargo, empresa e endereço do perfil.
- **Sem clique**, só nas páginas de vaga do LinkedIn: o endereço da aba (não o conteúdo da página), para
  perguntar ao seu WorkMachine se a vaga já está salva e mostrar a nota no ícone.

**Para onde os dados vão**

Só para o WorkMachine que roda no seu computador, no endereço configurado nas Opções (padrão
`http://localhost:3000`). A extensão não envia nada para outro lugar, não usa análise de uso
(analytics), não tem anúncios e não vende nem compartilha dados com terceiros.

**O que fica guardado na extensão**

O endereço do seu WorkMachine e o token de acesso, no armazenamento local do navegador
(`chrome.storage.local`). Eles servem só para a extensão falar com o seu WorkMachine e são apagados
quando você remove a extensão.

**O que a extensão não faz**

Não lê páginas sozinha, não navega, não clica, não se candidata a vagas e não coleta senhas, dados de
pagamento ou histórico de navegação.

## App WorkMachine

As vagas, candidaturas, contatos, currículo e senhas ficam no banco de dados do seu computador. O app só
se comunica com: as fontes públicas de vagas que ele consulta; o seu Gmail, em modo só leitura, se você
ligar; e o OpenRouter, com a sua chave, quando você usa uma função de IA (só o texto necessário para
aquela função). Detalhes no [README](README.md#privacidade).

## Dúvidas

Abra uma issue em [github.com/will-terra/WorkMachine/issues](https://github.com/will-terra/WorkMachine/issues).

---

# Privacy policy

Last updated: October 22, 2026.

WorkMachine is a job search app that runs on your own computer; the browser extension connects the pages
you visit to that app. There is no WorkMachine server: neither the author nor anyone else receives your data.

## Browser extension

**What the extension reads**

- **When you click its icon** on a job page: the job's title, company, location, address and description
  and, on LinkedIn jobs, the names and titles of the hiring team shown on the page.
- **When you click its icon** on a LinkedIn profile: name, title, company and profile address.
- **Without a click**, only on LinkedIn job pages: the tab's address (not the page content), to ask your
  WorkMachine whether the job is already saved and show its score on the icon.

**Where the data goes**

Only to the WorkMachine running on your computer, at the address set in the Options (default
`http://localhost:3000`). The extension sends nothing anywhere else, has no analytics or ads, and does
not sell or share data with third parties.

**What the extension stores**

Your WorkMachine address and access token, in the browser's local storage (`chrome.storage.local`), used
only to talk to your WorkMachine and removed when you uninstall the extension.

**What the extension does not do**

It does not read pages on its own, navigate, click, apply to jobs, or collect passwords, payment data or
browsing history.

## Questions

Open an issue at [github.com/will-terra/WorkMachine/issues](https://github.com/will-terra/WorkMachine/issues).
