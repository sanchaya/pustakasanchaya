module ApplicationHelper
 def clean_link link
  link.gsub('_', '.')
end
end
