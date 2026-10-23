<div align="center">

**English** · [Português (Brasil)](README.pt-BR.md)

<img src="app/assets/images/ruby.png" alt="" width="72">

# WorkMachine

### Your tech job search on autopilot, running on your own computer.

Pulls jobs from 10+ sources, scores each one against **your** profile, tracks your applications on a
kanban board, reads the companies' replies in your Gmail and uses AI to analyze jobs and write messages.
**Free, open source and 100% local**: your data never leaves your machine.

[![GitHub stars](https://img.shields.io/github/stars/will-terra/WorkMachine?style=for-the-badge&logo=github&color=c7262f)](https://github.com/will-terra/WorkMachine/stargazers)
[![CI](https://img.shields.io/github/actions/workflow/status/will-terra/WorkMachine/ci.yml?branch=main&style=for-the-badge&label=tests)](https://github.com/will-terra/WorkMachine/actions/workflows/ci.yml)
[![License AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-2c2726?style=for-the-badge)](LICENSE)
[![Rails 8.1](https://img.shields.io/badge/Rails-8.1-c7262f?style=for-the-badge&logo=rubyonrails&logoColor=white)](https://rubyonrails.org)
[![Chrome Web Store](https://img.shields.io/chrome-web-store/v/lohldenjhfbijbcolpglchnnionlbfaa?style=for-the-badge&logo=googlechrome&logoColor=white&label=extension&color=2c2726)](https://chromewebstore.google.com/detail/lohldenjhfbijbcolpglchnnionlbfaa)

**[Install in 5 minutes](#install)** · **[See the screens](#screen-tour)** · **[User guide](GUIDE.md)** · **[Leave a ⭐](https://github.com/will-terra/WorkMachine/stargazers)**

<br>

<img src=".github/readme/en/painel.png" alt="WorkMachine dashboard: today's routine, applications by status, new jobs by score, follow-ups and company replies" width="100%">

</div>

> [!TIP]
> **Like the idea?** Give the repository a ⭐: it's what gets the project to more people who are looking
> for a job, and it takes two seconds.

## Why WorkMachine

Looking for a tech job has become a second job. WorkMachine puts it all in one place and does the boring
part for you.

| | |
| - | - |
| 🎯 **A 0 to 100 score for every job** | Based on your skills, level, region and terms to avoid, with the math explained. The best ones show up first. |
| 🔎 **10+ sources, on its own** | Remotive, Gupy, Himalayas, Remotar, Programathor, Hacker News, Greenhouse and Lever boards, your LinkedIn alerts and more. Every 3 hours. |
| 📬 **Reads the companies' replies** | In your Gmail, read only: rejections, interviews, tests and offers move the card on the board by themselves. |
| 🤖 **AI that doesn't make things up** | Builds your profile from your CV, analyzes your fit, tailors your CV and writes messages. Uses a free model by default. |
| 🧭 **Kanban, metrics, Radar and routine** | Applications from saved job to offer, the funnel that shows what pays off, ready-made searches for what's done by hand and a daily routine. |
| 🔒 **On your computer** | Runs with Docker, no account, server or tracking. In English and Portuguese, and installable as an app. |

> No LinkedIn scraping and no automatic applying, which break the terms and put your account at risk: job
> alerts arrive through your Gmail, and the extension only reads a page when you click it.

## Screen tour

**Jobs:** triage with the score explained, keyboard shortcuts and AI analysis in one click.

<img src=".github/readme/en/vagas.png" alt="Jobs screen with the list by score and the job detail with the score breakdown" width="100%">

**Applications:** the kanban that updates itself with the companies' replies.

<img src=".github/readme/en/candidaturas.png" alt="Applications kanban with the details card open" width="100%">

**Radar:** the searches for what's done by hand, built from your profile, and the LinkedIn alerts to turn on.

<img src=".github/readme/en/radar.png" alt="Radar with the LinkedIn searches ready to copy or open" width="100%">

**Profile:** change a skill and see the scores change before you save.

<img src=".github/readme/en/perfil.png" alt="Profile with skill chips by level and the score preview on the side" width="100%">

**Metrics, Messages, Routine and Settings:**

<p>
  <img src=".github/readme/en/metricas.png" alt="Metrics: applications sent, reply rate, interviews, weekly chart and funnel" width="49%" align="top">
  <img src=".github/readme/en/mensagens.png" alt="Messages: template filled in with the contact's name and company" width="49%" align="top">
  <img src=".github/readme/en/rotina.png" alt="Routine: step-by-step app setup and job search routine" width="49%" align="top">
  <img src=".github/readme/en/ajustes.png" alt="Settings with language, keys and accounts, extension, notifications and auto-dismiss" width="49%" align="top">
</p>

## Install

You need a computer with Windows 10/11, macOS or Linux and
[Docker Desktop](https://www.docker.com/products/docker-desktop/) (open it once; on Windows it turns on
WSL2 by itself).

```bash
git clone https://github.com/will-terra/WorkMachine.git
cd WorkMachine
docker compose up -d
```

Without git: on GitHub, click **Code → Download ZIP**, unzip it and run `docker compose up -d` in the
folder. Then open **http://localhost:3000**, create your account (it only exists on your computer) and
follow the **First run**. To use it like a program, install it from the address bar icon in Chrome or Edge.

## First steps

The app opens with a step-by-step setup. The essentials:

- **Profile:** upload your CV and let the AI build the draft (with a free
  [OpenRouter](GUIDE.md#ai-openrouter) key), or fill it in by hand.
- **Gmail:** with an [app password](GUIDE.md#gmail), the app reads the LinkedIn alerts and the companies'
  replies.
- **Extension:** install it from the [Chrome Web Store](https://chromewebstore.google.com/detail/lohldenjhfbijbcolpglchnnionlbfaa)
  and paste the token from **Settings**.
- **Radar:** create your LinkedIn job alerts from the **LinkedIn alerts** section and check each one.

AI models and costs, Gmail, the extension, notifications, backup and troubleshooting: see the
**[user guide](GUIDE.md)**.

## Update

```bash
docker compose pull && docker compose up -d
```

## Privacy

WorkMachine runs only on your computer and sends no data to the author or to any server. All that leaves
it: the requests to the public job sources, the reading of your Gmail (if turned on) and, when you use the
AI, the text it needs to OpenRouter, with your key. Details in [PRIVACY.md](PRIVACY.md#privacy-policy).

## License and contributing

Open source under the [GNU AGPL-3.0](LICENSE). Found a problem or have a suggestion? Open an issue. To work
on the code, see [CONTRIBUTING.md](CONTRIBUTING.md) and [DEVELOPMENT.md](DEVELOPMENT.md) (in Portuguese).

---

<div align="center">

### Did WorkMachine help you?

A ⭐ is the simplest way to say thanks and to get the project to people who are looking for a job.

**[⭐ Star it on GitHub](https://github.com/will-terra/WorkMachine/stargazers)**

Made with Ruby on Rails, for people on the other side of the hiring process.

</div>
