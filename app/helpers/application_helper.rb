module ApplicationHelper
  include SlugHelper

  def person_slug_path(slug)
    admin_person_path(slug)
  end

  def sort_link(column, label, base_path)
    current_dir = params[:direction] || 'asc'
    direction = (params[:sort] == column && current_dir == 'asc') ? 'desc' : 'asc'
    arrow = params[:sort] == column ? (current_dir == 'asc' ? ' &#9650;' : ' &#9660;') : ''
    arrow_suffix = params[:sort] == column ? (current_dir == 'asc' ? ' ▲' : ' ▼') : ''
    link_to "#{label}#{arrow_suffix}".html_safe, "#{base_path}?sort=#{column}&direction=#{direction}", style: 'color: inherit; text-decoration: none;'
  end
end