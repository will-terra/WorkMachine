// Runs inside the job page (chrome.scripting.executeScript) only after the user clicks the
// extension. It must be self-contained: no imports and no outer variables.
// Order: JSON-LD schema.org/JobPosting, LinkedIn's job card, known ATS pages (Greenhouse, Lever),
// a generic description block, Open Graph and finally document.title.
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
                              ".show-more-less-html__markup", ".description__text")

    return {
      title: text(title?.innerText),
      company: text(company?.innerText),
      location_text: [text(place?.innerText), text(workplace?.innerText)].filter(Boolean).join(" · "),
      description: (description?.innerText || "").trim(),
      url: `https://www.linkedin.com/jobs/view/${id}`
    }
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
  for (const source of [fromJsonLd(), linkedIn, fromBoards(), fromOpenGraph(), fromTitle()]) {
    if (!source) continue
    for (const [key, value] of Object.entries(source)) {
      if (value && !merged[key]) merged[key] = value
    }
  }
  merged.url = linkedIn?.url || merged.url || location.href
  merged.description = (merged.description || "").slice(0, 20000)
  return merged
}
