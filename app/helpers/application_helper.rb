module ApplicationHelper
  def clean_link link
   link.gsub('_', '.') if link
 end

 def wiki_logo_class(book_in_wiki)
  book_in_wiki ? '' : 'wiki-dull-logo'
 end

end
