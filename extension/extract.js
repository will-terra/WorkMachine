// Runs inside the job page (chrome.scripting.executeScript) only after the user clicks the
// extension. It must be self-contained: no imports and no outer variables.
// Order: JSON-LD schema.org/JobPosting, LinkedIn's job card, known ATS pages (Greenhouse, Lever),
// a generic description block, Open Graph and finally document.title. On LinkedIn it also reads
// the hiring team, to save them as contacts.
export function extractJob() {
  const text = (value) => (value || "").replace(/\s+/g, " ").trim()
  const htmlToText = (html) => {
    if (!html) return ""
    const doc = new DOMParser().parseFromString(String(html), "text/html")
    doc.querySelectorAll("br").forEach((br) => br.replaceWith("\n"))
    doc.querySelectorAll("p, li, div, h1, h2, h3, h4, tr").forEach((node) => node.append("\n"))
    return (doc.body.textContent || "").replace(/[ \t\u00a0]+/g, " ").replace(/ *\n */g, "\n").replace(/\n{3,}/g, "\n\n").trim()
  }
  const meta = (name) => document.querySelector(`meta[property="${name}"], meta[name="${name}"]`)?.content || ""
  const first = (...selectors) => {
    for (const selector of selectors) {
      const node = document.querySelector(selector)
      if (node && text(node.innerText || node.textContent)) return node
    }
    return null
  }

  const fromJsonLd = () => {
    const found = []
    const visit = (node) => {
      if (!node || typeof node !== "object") return
      if (Array.isArray(node)) return node.forEach(visit)
      const type = [].concat(node["@type"] || [])
      if (type.includes("JobPosting")) found.push(node)
      if (node["@graph"]) visit(node["@graph"])
    }
    document.querySelectorAll('script[type="application/ld+json"]').forEach((script) => {
      try { visit(JSON.parse(script.textContent)) } catch (_) { /* invalid JSON-LD: ignore */ }
    })
    const job = found[0]
    if (!job) return null

    const places = [].concat(job.jobLocation || []).map((place) => {
      const address = place.address || {}
      const country = typeof address.addressCountry === "object" ? address.addressCountry.name : address.addressCountry
      return [address.addressLocality, address.addressRegion, country].filter(Boolean).join(", ")
    }).filter(Boolean)
    const applicants = [].concat(job.applicantLocationRequirements || []).map((req) => req.name).filter(Boolean)
    const remote = job.jobLocationType === "TELECOMMUTE" ? "Remoto" : ""
    const salary = job.baseSalary?.value
    const salaryText = salary ? [job.baseSalary.currency, salary.minValue, salary.maxValue && `– ${salary.maxValue}`, salary.unitText].filter(Boolean).join(" ") : ""

    return {
      title: text(job.title),
      company: text(typeof job.hiringOrganization === "object" ? job.hiringOrganization.name : job.hiringOrganization),
      description: htmlToText(job.description),
      location_text: [remote, ...places, ...applicants].filter(Boolean).join(" · "),
      salary_text: salaryText,
      posted_at: job.datePosted || "",
      url: job.url || ""
    }
  }

  // When LinkedIn renames its classes: the block around the "About the job" heading. The server
  // keeps only what follows the heading (LinkedinJobText).
  const aboutTheJob = () => {
    const heading = [...document.querySelectorAll("h2, h3")]
      .find((node) => /^(?:about the job|sobre a vaga|acerca del empleo)$/i.test(text(node.innerText)))
    for (let node = heading?.parentElement, depth = 0; node && depth < 5; node = node.parentElement, depth++) {
      if (text(node.innerText).length > text(heading.innerText).length + 100) return node
    }
    return null
  }

  const fromLinkedIn = () => {
    if (!/(^|\.)linkedin\.com$/.test(location.hostname)) return null
    const id = location.pathname.match(/\/jobs\/view\/(?:[^/]*-)?(\d+)/)?.[1] || new URLSearchParams(location.search).get("currentJobId")
    if (!id) return null

    const title = first(".job-details-jobs-unified-top-card__job-title h1", ".job-details-jobs-unified-top-card__job-title",
                        ".jobs-unified-top-card__job-title", ".top-card-layout__title", "h1.t-24", "main h1")
    const company = first(".job-details-jobs-unified-top-card__company-name a", ".job-details-jobs-unified-top-card__company-name",
                          ".jobs-unified-top-card__company-name", ".topcard__org-name-link", ".top-card-layout__second-subline a")
    const place = first(".job-details-jobs-unified-top-card__primary-description-container .tvm__text",
                        ".job-details-jobs-unified-top-card__bullet", ".jobs-unified-top-card__bullet", ".topcard__flavor--bullet")
    const workplace = first(".job-details-fit-level-preferences button", ".jobs-unified-top-card__workplace-type")
    const description = first("#job-details", ".jobs-description__content", ".jobs-description-content__text",
                              ".show-more-less-html__markup", ".description__text") || aboutTheJob()

    return {
      title: text(title?.innerText),
      company: text(company?.innerText),
      location_text: [text(place?.innerText), text(workplace?.innerText)].filter(Boolean).join(" · "),
      description: (description?.innerText || "").trim(),
      url: `https://www.linkedin.com/jobs/view/${id}`
    }
  }

  // "Meet the hiring team" ("Conheça a equipe de contratação") or the public page's recruiter box.
  // Only the profiles under that heading: the nav's link to your own profile is outside it.
  const fromHiringTeam = () => {
    if (!/(^|\.)linkedin\.com$/.test(location.hostname)) return []
    const slugOf = (link) => link.href.match(/linkedin\.com\/in\/([^/?#]+)/i)?.[1]
    const heading = [...document.querySelectorAll("h2, h3")]
      .find((node) => /hiring team|equipe de contrata|time de contrata|message the (?:job poster|recruiter)|anunciante da vaga/i.test(node.innerText || ""))
    let scope = null
    for (let node = heading?.parentElement, depth = 0; node && depth < 4 && !scope; node = node.parentElement, depth++) {
      if (node.querySelector("a[href*='/in/']")) scope = node
    }
    scope ||= document.querySelector(".job-details-people-who-can-help__section, .message-the-recruiter")
    if (!scope) return []

    // "Mariana Souza • 3rd" or "Mariana Souza (She/Her)" → "Mariana Souza"
    const cleanName = (value) => text((value || "").split("\n")[0]).replace(/\s*[·•].*$/, "").replace(/\s*\(.*\)$/, "")
    const people = new Map()
    for (const link of scope.querySelectorAll("a[href*='/in/']")) {
      const slug = slugOf(link)
      if (!slug) continue
      const person = people.get(slug) || { slug, name: "", link }
      person.name ||= cleanName(link.innerText)
      people.set(slug, person)
    }

    const headingText = text(heading?.innerText)
    const noise = /^(?:[·•]\s*)?(?:1st|2nd|3rd\+?|[123]º\+?|job poster|anunciante da vaga|message|mensagem|enviar mensagem|follow|seguir|connect|conectar|view profile|ver perfil|verified|verificad[oa])$/i
    return [...people.values()].filter((person) => person.name).slice(0, 3).map(({ slug, name, link }) => {
      // The largest block around the person that holds no one else: name, degree, headline…
      let card = link
      while (card !== scope && new Set([...card.parentElement.querySelectorAll("a[href*='/in/']")].map(slugOf).filter(Boolean)).size === 1) {
        card = card.parentElement
      }
      const headline = (card.innerText || "").split("\n").map(text)
        .find((line) => line.length > 2 && !line.startsWith(name) && line !== headingText && !noise.test(line)) || ""
      return { name, headline, linkedin_url: `https://www.linkedin.com/in/${slug}` }
    })
  }

  const fromBoards = () => {
    const title = first(".job__title h1", "h1.app-title", ".posting-headline h2", "[data-qa='job-title']")
    const place = first(".job__location", "#header .location", ".posting-categories .location", ".posting-category.location")
    const description = first(".job__description", "#content .content-intro, #content", "[data-qa='job-description']",
                              ".posting-page .section-wrapper.page-full-width", "[class*='job-description']",
                              "[class*='jobDescription']", "[class*='description']", "article", "main")
    // Greenhouse titles read "Job Application for <role> at <company>".
    const company = document.title.match(/^Job Application for .+ at (.+)$/)?.[1] ||
                    text(first(".company-name")?.innerText).replace(/^at\s+/i, "")
    return {
      title: text(title?.innerText),
      company: text(company),
      location_text: text(place?.innerText),
      description: (description?.innerText || "").trim()
    }
  }

  // og:site_name is usually the ATS or the site, not the company, so it is not used.
  const fromOpenGraph = () => ({
    title: text(meta("og:title")),
    description: text(meta("og:description") || meta("description")),
    url: meta("og:url")
  })

  const fromTitle = () => {
    const greenhouse = document.title.match(/^Job Application for (.+) at (.+)$/)
    if (greenhouse) return { title: text(greenhouse[1]), company: text(greenhouse[2]) }
    const [title, company] = document.title.split(/\s+[|–-]\s+/)
    return { title: text(title), company: text(company) }
  }

  const linkedIn = fromLinkedIn()
  const merged = {}
  // On LinkedIn the generic blocks (main, article) are the whole page, not the description.
  for (const source of [fromJsonLd(), linkedIn, linkedIn ? null : fromBoards(), fromOpenGraph(), fromTitle()]) {
    if (!source) continue
    for (const [key, value] of Object.entries(source)) {
      if (value && !merged[key]) merged[key] = value
    }
  }
  merged.url = linkedIn?.url || merged.url || location.href
  merged.description = (merged.description || "").slice(0, 20000)
  merged.people = fromHiringTeam()
  return merged
}

// Runs on a LinkedIn profile (/in/...) only after the user clicks the extension. Self-contained,
// like extractJob. Reads the top card: name, headline and current company.
export function extractProfile() {
  const text = (value) => (value || "").replace(/\s+/g, " ").trim()
  const slug = location.pathname.match(/^\/in\/([^/]+)/)?.[1]
  if (!/(^|\.)linkedin\.com$/.test(location.hostname) || !slug) return null

  const nameNode = document.querySelector("main h1") || document.querySelector("h1")
  // The tab title reads "(3) Mariana Souza | LinkedIn".
  const name = text(nameNode?.innerText) || text(document.title.replace(/^\(\d+\)\s*/, "").split(/\s+[|–-]\s+/)[0])
  const card = nameNode?.closest("section") || nameNode?.parentElement?.parentElement
  const noise = /^(?:[·•]\s*)?(?:1st|2nd|3rd\+?|[123]º\+?|verified|verificad[oa]|contact info|informações de contato)$|^\(.*\)$|^(?:he|she|they|ele|ela)\//i
  let headline = text(card?.querySelector(".text-body-medium")?.innerText)
  if (!headline && card) {
    headline = (card.innerText || "").split("\n").map(text)
      .find((line) => line.length > 2 && !(name && line.startsWith(name)) && !noise.test(line)) || ""
  }

  // "Current company: Acme. Click to skip to experience card", or the headline's "at Acme" / "@Acme".
  const current = document.querySelector("main [aria-label^='Current company'], main [aria-label^='Empresa atual']")?.getAttribute("aria-label")
  const company = current
    ? current.replace(/^(?:Current company|Empresa atual):\s*/i, "").replace(/\.\s*(?:Click|Clique).*$/i, "")
    : headline.match(/(?:\b(?:at|na|no)\s+|@\s*)([A-Z0-9À-Ý][^|·•,]*)/)?.[1]

  return { name, headline, company: text(company), linkedin_url: `https://www.linkedin.com/in/${slug}` }
}
