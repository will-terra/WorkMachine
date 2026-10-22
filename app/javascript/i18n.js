// Texts of the Stimulus controllers, in the interface language: the layout puts the "js" keys of
// config/locales in <meta name="i18n">. t("push.enabled"), t("push.failed", { error: "…" }).
let texts

export function t(key, values = {}) {
  texts ||= JSON.parse(document.querySelector("meta[name='i18n']")?.content || "{}")
  const text = key.split(".").reduce((node, part) => node?.[part], texts) ?? key
  return text.replace(/%\{(\w+)\}/g, (_, name) => values[name] ?? "")
}
