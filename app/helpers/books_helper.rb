module BooksHelper

  def archive_url(metadata)
    # if keyword matches for split then result will always be more than 1
    metadata.split('archive_url:').count > 1
  end

# very hard and worst way of fetching the link, should think of changing it
  def wikimedia_url(metadata)
    links = metadata.split("\n")
    @url = ''
    links.each do |meta|
      if meta.include?('archive_url:') and !meta.include?('old_archive_url:')
        @url = meta.split('archive_url:').last
      end
    end 
    return @url
  end

  


  # very hard and worst way of fetching the link, should think of changing it
  def wikisource_url(metadata)
    links = metadata.split("\n")
    @url = ''
    links.each do |meta|
      if meta.include?('wikisource_url:')
        @url = meta.split('wikisource_url:').last
      end
    end 
    return @url
  end

  def clean_file_name(file_name)
    return file_name + '.djvu'
  end


end
