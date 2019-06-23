module ApplicationHelper

  def clean_link link
   link.gsub('_', '.') if link
  end

  def wiki_logo_class(book_in_wiki)
  book_in_wiki ? '' : 'wiki-dull-logo'
  end

  def wiki_logo_title(book_in_wiki)
    book_in_wiki ? 'ವಿಕಿಯಲ್ಲಿ ಈ ಪುಟ ಸೃಷ್ಟಿಯಾಗಿದೆ.' : 'ವಿಕಿಯಲ್ಲಿ ಈ ಪುಟ ಸೃಷ್ಟಿಯಾಗಿರುವುದಿಲ್ಲ.'
  end

  def get_commons_filename(url)
    filename = url.split('https://commons.wikimedia.org/wiki/File:').last
    filename = filename.split('.djvu').last if filename
    return filename
  end

  def get_wikisource_filename(url)
    filename = url.split('https://kn.wikisource.org/wiki/Index:').last
    filename = filename.split('.djvu').last if filename
    return filename
  end

  

end
