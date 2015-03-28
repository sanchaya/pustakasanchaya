module ApplicationHelper
 def clean_link link
  link.gsub('_', '.') if link
end
end
