module ApplicationHelper
  def nav_items
    [
      [ "Painel", root_path ],
      [ "Candidaturas", job_applications_path ],
      [ "Radar", radar_path ],
      [ "Mensagens", message_templates_path ],
      [ "Rotina", routine_path ],
      [ "Contatos", contacts_path ]
    ]
  end

  def nav_link(label, path)
    active = path == root_path ? current_page?(root_path) : request.path.start_with?(path)
    link_to label, path, class: [ "nav-link", ("nav-link-active" if active) ], aria: { current: (active ? "page" : nil) }
  end

  def page_header(eyebrow:, title:, intro: nil, &actions)
    content_for :title, title
    tag.header(class: "mb-6 flex flex-wrap items-end justify-between gap-4") do
      safe_join([
        tag.div do
          safe_join([
            tag.p(eyebrow, class: "eyebrow"),
            tag.h1(title, class: "mt-1"),
            (tag.p(intro, class: "muted mt-2 max-w-prose text-sm") if intro)
          ].compact)
        end,
        (tag.div(class: "flex flex-wrap items-center gap-2", &actions) if actions)
      ].compact)
    end
  end

  def short_date(date)
    date ? l(date.to_date, format: "%d/%m/%y") : "—"
  end

  def external_link(label, url, **options)
    return label if url.blank?

    link_to label, url, target: "_blank", rel: "noopener noreferrer", **options
  end
end
