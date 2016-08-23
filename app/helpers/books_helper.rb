module BooksHelper

  def archive_url(metadata)
    # if keyword matches for split then result will always be more than 1
    metadata.split('archive_url:').count > 1
  end

  def wikimedia_url(metadata)
    # if keyword matches for split then result will always be more than 1
    metadata.split('wikimedia_url:').count > 1
  end


end
