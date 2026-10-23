# WorkMachine user guide

**English** · [Português (Brasil)](GUIDE.pt-BR.md)

The details the [README](README.md) sums up. To install, see [Install](README.md#install).

[First steps](#first-steps) · [Screens](#screens) · [Automatic sources](#automatic-sources) ·
[AI](#ai-openrouter) · [Gmail](#gmail) · [Extension](#browser-extension) ·
[Notifications](#notifications) · [Backup and data](#backup-and-data) · [Troubleshooting](#troubleshooting)

## First steps

The app opens with the **App setup** routine: a step-by-step list with a link to each screen. In short:

1. **Profile.** Upload your CV (PDF, DOCX or TXT) and click **Build profile from the CV**: the AI fills
   in a draft that you review before saving. Adjust the area, the target titles, the level and the skills
   in three levels. The preview on the side shows how the scores turn out. Without AI, fill it in by
   hand: the screen suggests titles and skills for your area.
2. **Jobs.** Every 3 hours the aggregator searches with your profile's terms. In the triage, save the
   good ones (they become applications) and dismiss the rest.
3. **Applications.** Move the cards on the board. With Gmail connected, the companies' replies
   (rejection, interview, test, offer) move the cards by themselves. Invitations to asynchronous
   interviews (recorded video or audio, AI interviews such as HireVue and Willo) go to the
   **AI interview** column.
4. **Radar.** What to do by hand, by frequency, with the searches already built for your profile. Create
   your LinkedIn job alerts from the searches in the **LinkedIn alerts** section and check each one as
   turned on: when the profile changes, the new alerts show up there.

## Screens

| Screen | What it's for |
| - | - |
| **Dashboard** | Today's routine, new jobs by score, today's follow-ups and the companies' replies. |
| **Jobs** | Triage with filters and sorting: save, save as applied, dismiss, analyze with AI, mark as a dream job. Shortcuts: `S` saves, `A` saves as applied, `D` dismisses. |
| **Applications** | Kanban and table, the company's e-mails in each application, `.xlsx` and CSV export. |
| **Routine** | Daily and weekly checklist and the step-by-step app setup. Routines are edited in **Settings → Routines**. |
| **Radar** | What to do by hand: LinkedIn alerts to turn on, LinkedIn posts and people, X, Google, Telegram groups, sites without an API and sign-ups. |
| **Contacts** and **Target companies** | Recruiters and hiring managers; companies whose job boards the aggregator reads. |
| **Messages** | Message templates filled in with the job, the contact and your profile, with a character counter for LinkedIn's connection note. |
| **Metrics** | Applications per week, funnel, reply and interview rates by origin and the sources that pay off most. |
| **Profile** | Who you are and what you're looking for: the score, the searches, the Radar and the AI come from it. |
| **Settings** | Language, keys and accounts, extension, notifications, auto-dismiss, sources, routines and backup. |

The interface follows your browser's language (Portuguese for pt-BR and pt-PT, English for everything
else), and you can pick one in **Settings → Language**.

## Automatic sources

Remotive, Remote OK, We Work Remotely, Working Nomads, Himalayas, Remotar, Gupy, Programathor, Vagas.com,
Telegram channels (for junior profiles), backend-br and frontendbr (GitHub), Hacker News "Who is hiring",
GoRails Jobs and the Greenhouse, Lever, Ashby and Workable boards of your target companies, plus your
LinkedIn alerts through Gmail. The niche ones only run when they match your profile, and each one can be
turned off in Settings. Every source respects the limits and the credits its API asks for, and what each
site's robots.txt allows.

WorkMachine **does not scrape LinkedIn and does not apply on its own**: that breaks LinkedIn's terms and
puts your account at risk. Job alerts arrive through your Gmail, and the browser extension only reads a
page when you click it.

## AI (OpenRouter)

1. Create an account at [openrouter.ai](https://openrouter.ai).
2. Create a key at [Settings → Keys](https://openrouter.ai/settings/keys) and paste it in **Settings →
   Keys and accounts** (or in the First run). Use **Test OpenRouter** to check it.
3. Choose the model in **Settings → Keys and accounts → Model**:

| | Free (default) | Paid |
| - | - | - |
| Model | MiniMax M3.1 Flash (`minimax/minimax-m3.1-flash:free`); if it's down or at its limit, OpenRouter picks another free model (`openrouter/free`) | DeepSeek V4 Pro (`deepseek/deepseek-v4-pro-0813`), or any other OpenRouter model you type in |
| Cost | None; no credit needed | Cents of a dollar a month with normal use; needs credits at [Settings → Credits](https://openrouter.ai/settings/credits) |
| Limits | OpenRouter limits free requests per minute and per day (the daily limit goes up once you have bought credits). When you go over, the AI tells you and works again later | No tight limit |
| Your data | The providers of the free models may store and use what you send (CV, jobs, company e-mails) to train models | Each provider's policy applies, which you see and control at [Settings → Privacy](https://openrouter.ai/settings/privacy) |

If OpenRouter refuses the free models because of your data policy, allow them at
[Settings → Privacy](https://openrouter.ai/settings/privacy) or switch to the paid model. The ids of the
free models change over time; that's why the app has `openrouter/free` as a fallback.

The AI only runs when you click: building the profile, analyzing the fit, tailoring the CV summary or
writing a message. The exception is reading the companies' replies in Gmail, which runs on its own. On
the paid model, the button shows the estimated cost beforehand, and every result keeps its real cost.
Building your profile from your CV costs less than 1 cent. The AI only uses the facts in your profile and
never invents experience.

## Gmail

WorkMachine reads the LinkedIn alerts and the companies' replies in Gmail. It signs in with an **app
password**: a 16-letter password, separate from your account password, that Google creates for a single
program. Your regular account password doesn't work.

1. Turn on **2-Step Verification** for your Google account: at
   [myaccount.google.com/security](https://myaccount.google.com/security), **2-Step Verification** →
   **Turn on**. Without it, Google doesn't offer app passwords.
2. Open [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords) (Google may ask
   for your password again), type the name "WorkMachine" and click **Create**.
3. Copy the 16 letters that show up. They are shown only once; if you lose them, delete that password
   and create another one. The spaces between the blocks don't matter.
4. In **Settings → Keys and accounts**, enter the e-mail and the app password and click **Test Gmail**.
5. On LinkedIn, create your job alerts (by e-mail, daily) from the Radar's searches (**Once → LinkedIn
   alerts**) and check each one as turned on.

WorkMachine opens the mailbox read only: nothing is marked as read, moved or deleted. Every hour it
imports the LinkedIn alerts and looks for the replies from the companies you applied to. The first time,
it looks at the alerts from the last 14 days and the replies from the last 30.

Common problems:

- **The app passwords page says the option isn't available:** 2-Step Verification is off, the account
  belongs to work or school (the administrator may have blocked it) or the account uses Google's
  Advanced Protection. In the last two cases, use another Gmail account to receive the alerts.
- **"Test Gmail" says Google requires an app password:** the regular account password was used. Create
  the app password and paste the 16 letters.
- **The LinkedIn alerts don't reach the app:** if a Gmail filter takes the alerts out of the inbox,
  WorkMachine doesn't see them. Remove the filter, or make the app read every e-mail with the line
  `GMAIL_MAILBOX=[Gmail]/All Mail` in `.env` (`[Gmail]/Todos os e-mails` if your Gmail is in Portuguese);
  then run `docker compose up -d`.
- **To cut access:** delete the "WorkMachine" password at
  [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords). Your account password
  doesn't change, and the app stops reading the mailbox right away.

## Browser extension

It saves the job open in any site (LinkedIn, Greenhouse, Lever, Gupy, career pages…) to WorkMachine,
shows on its icon the score of the LinkedIn jobs already in the app and saves recruiters to Contacts.

1. Install it from the **[Chrome Web Store](https://chromewebstore.google.com/detail/lohldenjhfbijbcolpglchnnionlbfaa)**. It works in Chrome and in Edge (in Edge,
   allow extensions from other stores when it asks).
2. In **Settings → Browser extension**, click **Generate token** and copy it.
3. Pin the icon to the toolbar, open the extension's **Options**, paste the token and click
   **Test connection**.

That's it: the store keeps the extension up to date by itself.

## Notifications

In **Settings**, click **Turn on notifications** (preferably inside the installed app). You get alerts
for new jobs with a high score (default 40), for the companies' replies and, at 8 a.m., for the day's
follow-ups. Each kind can be turned off.

## Backup and data

Everything lives in Docker's `storage` volume: the database, your CV and the keys that encrypt the
passwords.

- **Automatic backup:** every hour the database is copied to the `backups` folder inside the WorkMachine
  folder. The copies from the last 24 hours and one a day from the last 14 days are kept. To save them
  in another folder (one that already syncs to the cloud, for example), create a `.env` file in the
  WorkMachine folder with the line `WORKMACHINE_BACKUP_DIR=` and the folder's path (examples in
  [DEVELOPMENT.md](DEVELOPMENT.md#variáveis-de-ambiente)); then run `docker compose up -d`.
- **Spreadsheet:** Applications → Export .xlsx or Export CSV.
- **Restore a backup** (change the file name):
  ```bash
  docker compose stop web
  docker compose run --rm --no-deps --entrypoint sh web -c \
    'cp backups/workmachine-YYYY-MM-DD-HHMM.sqlite3 storage/production.sqlite3 && rm -f storage/production.sqlite3-wal storage/production.sqlite3-shm'
  docker compose start web
  ```
  The passwords saved in Settings only open with the `storage/workmachine-secrets.yml` file of the same
  volume. On a new volume, enter the keys again in Settings.
- **Delete everything:** `docker compose down -v` removes the app and the volume with the data. The
  backups stay.

## Troubleshooting

- **Port 3000 is already in use:** change `127.0.0.1:3000:3000` to `127.0.0.1:3001:3000` in
  `docker-compose.yml` and open http://localhost:3001 (change the address in the extension's Options too).
- **I forgot my password:**
  ```bash
  docker compose exec web bin/rails runner 'User.first.update!(password: "a-new-password")'
  ```
- **See what's going on:** `docker compose logs -f web`.
- **Search for jobs now:** **Search now** button in Jobs.
- **Gmail problems:** see [Gmail](#gmail).
