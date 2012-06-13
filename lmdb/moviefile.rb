
require 'set'

class MovieFile
  attr_accessor :movie_id
  attr_accessor :file
  attr_accessor :media_ids

  def initialize
    
  end

  def media_ids
    if not @media_ids
      @media_ids=Set.new
    end
    return @media_ids
  end
  
  def title
    return Imdb::scan_filename(@file)['title']
  end

  def year
    return Imdb::scan_filename(@file)['year']
  end

  def name
    File.basename(file)
  end

  def <=> other
    file <=> other.file
  end
  
  def to_s
    return "%s => %s" % [file, movie_id] 
  end

end




