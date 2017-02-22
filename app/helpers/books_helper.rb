module BooksHelper

  def archive_url(metadata)
    # if keyword matches for split then result will always be more than 1
    metadata.split('archive_url:').count > 1
  end

# very hard and worst way of fetching the link, should think of changing it
  def wikimedia_url(metadata)
     links = metadata.split('.djvu')
     @url = ''
     links.each do |link|
        if link.include?('wikimedia')
          @url = clean_file_name(link.split('wikimedia_url:').last)
        end
     end
     return @url
  end

  # very hard and worst way of fetching the link, should think of changing it
  def wikisource_url(metadata)
     # links = metadata.split('.djvu')
     # links.each do |link|
      # if link.include?('wikisource')
      #   return clean_file_name(link.split('wikisource_url:').last)
      # end
     # end
  end

  def clean_file_name(file_name)
    return file_name + '.djvu'
  end


end
