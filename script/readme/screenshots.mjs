// Screenshots of the READMEs (.github/readme/<language>/*.png), taken from the app running with the
// fictional data of script/readme/demo_data.rb in the same language. Needs Playwright
// (npm i -g playwright) and the app on :3000:
//
//   bin/rails db:reset && bin/rails runner script/readme/demo_data.rb && bin/dev
//   node script/readme/screenshots.mjs http://localhost:3000 pt-BR      # README.pt-BR.md
//
//   bin/rails db:reset && DEMO_LOCALE=en bin/rails runner script/readme/demo_data.rb && bin/dev
//   node script/readme/screenshots.mjs http://localhost:3000 en         # README.md
import { createRequire } from "node:module"

const require = createRequire(import.meta.url)
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || "playwright")
const base = process.argv[2] || "http://localhost:3000"
const language = process.argv[3] || "pt-BR"
const out = new URL(`../../.github/readme/${language}/`, import.meta.url).pathname

const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {})
// The interface follows the browser's language (Ajustes → Idioma stays on Automático).
const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1, colorScheme: "dark",
                                    locale: language === "en" ? "en-US" : "pt-BR" })
await page.goto(`${base}/session/new`)
await page.fill("input[name=email_address]", "demo@workmachine.local")
await page.fill("input[name=password]", "workmachine")
await page.click("[type=submit]")
await page.waitForLoadState("networkidle")

const shot = async (name, path, { height = 900, before } = {}) => {
  await page.setViewportSize({ width: 1440, height })
  await page.goto(`${base}${path}`)
  await page.waitForLoadState("networkidle")
  if (before) await before()
  await page.waitForTimeout(700)
  await page.screenshot({ path: `${out}${name}.png` })
}

await shot("painel", "/", { height: 1000 })
await shot("vagas", "/vagas", { height: 1000 })
await shot("candidaturas", "/candidaturas", { height: 720,
  before: async () => { await page.hover("ol[data-status=ai_interview] li"); await page.waitForTimeout(400) }
})
await shot("metricas", "/metricas", { height: 1000 })
await shot("radar", "/radar", { height: 1000 })
await shot("mensagens", "/mensagens?contact_id=1", { height: 900,
  // In English, the English connection note (the contact opens the Portuguese one).
  before: language === "en" ? async () => { await page.getByRole("option", { name: /Connection note/ }).click() } : undefined
})
await shot("rotina", "/rotina", { height: 1000 })
await shot("perfil", "/perfil", {
  height: 1000,
  before: async () => {
    const input = page.locator("[data-level=important] [data-profile-form-target=typed]")
    await input.fill("Kubernetes, TypeScript")
    await input.press("Enter")
    await page.waitForTimeout(1500)
  }
})
await shot("ajustes", "/ajustes", { height: 900 })

await browser.close()
console.log(`Prints em ${out}`)
