// Texts from _locales: chrome.i18n follows the browser's language (Portuguese for pt-BR and pt-PT,
// English for the others). In the pages, data-i18n fills the text and data-i18n-<attribute> an attribute.
export function t(key, ...values) {
  return chrome.i18n.getMessage(key, values.map(String)) || key
}

export function localize(root = document) {
  if (root === document) document.documentElement.lang = t("lang")
  for (const node of root.querySelectorAll("[data-i18n]")) node.textContent = t(node.dataset.i18n)
  for (const attribute of ["placeholder", "aria-label", "title"]) {
    for (const node of root.querySelectorAll(`[data-i18n-${attribute}]`)) node.setAttribute(attribute, t(node.getAttribute(`data-i18n-${attribute}`)))
  }
}
