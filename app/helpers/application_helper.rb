module ApplicationHelper
  def nav_items
    [
      [ "Painel", root_path ]
    ]
  end

  def nav_link(label, path)
    active = path == root_path ? current_page?(root_path) : request.path.start_with?(path)
    link_to label, path, class: [ "nav-link", ("nav-link-active" if active) ], aria: { current: (active ? "page" : nil) }
  end
end
