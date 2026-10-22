module ApplicationHelper
  # [label, path, count]: Vagas shows how many postings wait for triage.
  def nav_items
    [
      [ t("layouts.nav.dashboard"), root_path ],
      [ t("layouts.nav.postings"), job_postings_path, JobPosting.triage_new.count ],
      [ t("layouts.nav.applications"), job_applications_path ],
      [ t("layouts.nav.routine"), routine_path ],
      [ t("layouts.nav.radar"), radar_path ],
      [ t("layouts.nav.contacts"), contacts_path ],
      [ t("layouts.nav.messages"), message_templates_path ],
      [ t("layouts.nav.target_companies"), target_companies_path ],
      [ t("layouts.nav.metrics"), metrics_path ]
    ]
  end

  # A routine item with the profile's words ({{termos}}, {{area}}…).
  def routine_label(item)
    (@routine_terms ||= SearchTerms.new(Profile.current)).render_text(item.label)
  end

  # Line icons (24×24, drawn with the text color) for the places where a word does not fit.
  ICONS = {
    user: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
    sliders: '<path d="M4 6h9M17 6h3M4 12h3M11 12h9M4 18h11M19 18h1"/><circle cx="15" cy="6" r="2"/><circle cx="9" cy="12" r="2"/><circle cx="17" cy="18" r="2"/>',
    sign_out: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5M21 12H9"/>'
  }.freeze

  def icon(name, size: 20, **options)
    tag.svg(ICONS.fetch(name).html_safe, width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
            "stroke-width": 1.8, "stroke-linecap": "round", "stroke-linejoin": "round", aria: { hidden: true }, **options)
  end

  def nav_link(label, path, count: nil, **options)
    active = path == root_path ? current_page?(root_path) : request.path.start_with?(path)
    link_to path, class: [ "nav-link", ("nav-link-active" if active), options[:class] ], aria: { current: (active ? "page" : nil) } do
      safe_join([ label, (tag.span((count if count.positive?), id: "nav_count", class: "nav-count") if count) ].compact)
    end
  end

  def page_header(eyebrow:, title:, intro: nil, &actions)
    content_for :title, title
    tag.header(class: "panel mt-6 mb-7 flex flex-wrap items-end justify-between gap-x-8 gap-y-5 max-sm:mt-4 max-sm:mb-5 max-sm:gap-y-4") do
      safe_join([
        tag.div(class: "max-w-[64ch]") do
          safe_join([
            tag.p(eyebrow, class: "eyebrow"),
            tag.h1(title, class: "mt-2.5"),
            (tag.p(intro, class: "mt-3 text-[15.5px] leading-relaxed max-sm:mt-2 max-sm:text-[14.5px] max-sm:leading-normal") if intro)
          ].compact)
        end,
        (tag.div(class: "page-actions flex flex-wrap items-end gap-2.5", &actions) if actions)
      ].compact)
    end
  end

  def short_date(date)
    date ? l(date.to_date, format: :compact) : "—"
  end

  # "hoje 12:40", "ontem 09:00" or "18/10 14:32" ("today 12:40", "Oct 18 14:32" in English).
  def short_time(time)
    return "—" unless time

    day = time.to_date
    prefix = if day == Date.current then t("helpers.time.today")
    elsif day == Date.yesterday then t("helpers.time.yesterday")
    else l(day, format: :day_month)
    end
    "#{prefix} #{l(time, format: :hour)}"
  end

  # Contatos: "nunca", "hoje", "ontem" or "há 12 dias".
  def days_ago(date)
    return t("helpers.time.never") unless date

    days = (Date.current - date).to_i
    case days
    when ..0 then t("helpers.time.today")
    when 1 then t("helpers.time.yesterday")
    else t("helpers.time.days_ago", count: days)
    end
  end

  # Score bands: ≥ 60 in red, 35–59 in the text color, below that muted.
  def score_class(score)
    if score >= 60 then "score-high"
    elsif score >= 35 then "score-mid"
    else "score-low"
    end
  end

  # "+30" and "−15", with the typographic minus.
  def points(value)
    value.negative? ? "−#{value.abs}" : "+#{value}"
  end

  # "/mnt/c/Users/x/backups" (WSL) is shown as "C:\Users\x\backups".
  def windows_path(path)
    return path.to_s unless path.to_s.start_with?("/mnt/")

    path.to_s.sub(%r{\A/mnt/([a-z])/}) { "#{$1.upcase}:\\" }.tr("/", "\\")
  end

  def external_link(label, url, **options)
    return label if url.blank?

    link_to label, url, target: "_blank", rel: "noopener noreferrer", **options
  end
end
