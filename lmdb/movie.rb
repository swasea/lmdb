require 'rubygems' 
require 'unicode'

class String
  def movie?
    return self =~ /\.((avi)|(ogg)|(ogm)|(mpg)|(mpeg))$/
  end
end

class Movie
  attr_accessor :title
  attr_accessor :genre
  attr_accessor :poster
  attr_accessor :rating
  attr_accessor :director
  attr_accessor :year
  attr_accessor :votes

  def html_short_entry(db)
    puts "add entry for " + self.to_s
    result = '<div class="short_entry">' 
    if  File.exists?(poster_filename(db))
      if not File.exists?(local_poster_link)
        File.copy(poster_filename(db), local_poster_link)
      end
      result << '<img alt="poster" src="' << local_poster_link << '">'
    end
    result << '  <div class="title">'    << html_imdb_link << '</div>' << "\n"
  
    media_ids=db.movie_files[imdbid].collect { |each| each.media_ids }.to_set.flatten
    media_ids.each { | each_medium_id|
      files= db.movie_files[imdbid].select { |each| each.media_ids.include?(each_medium_id)}
      medium=db.media[each_medium_id]
      result << medium.html_div_files(files) if medium
    }
    if director
      result << '  <div class="director">' << director.to_s << '</div>'<< "\n" 
    end
    if rating
      result << '  <div class="rating">'   << rating.to_s << '</div>' << "\n" 
    end
    if votes
      result << '  <div class="votes"> ('   << votes.to_s << ' votes) </div>'  << "\n"
    end
    if genre
      result << '  <div class="genre">'   
      genre[0..-2].each { |each|
        result << each.to_s << ' / ' 
      }
      result << genre[-1].to_s
      result << "</div>"  << "\n"
    end
    result << '<div class="id">'<< imdbid.to_s << '</div>'  << "\n"
    result << '<br clear="both">'
    result << "</div>" << "\n"
    return result
  end
  
  def html_imdb_link
    if title
      title_s=  title + " "
      title_s << "(%s)" % year if year
    else
      title_s = "no title"
    end
    return "<a href=\"http://german.imdb.com/title/%s\">%s</a>" % 
      [imdbid, title_s] 
  end
  
  def rating
    if @rating
      return @rating
    else
      return 0.0
    end
  end

  def <=> other
    return -1 if not title or not other.title
    return title <=> other.title
  end

  def to_s
    "%s %s %s [%s %s]" % [imdbid, title, year, director, rating]
  end

  def scaned?
    return (@genre and @poster and @rating and @director)
  end

  def scan(html)
    scan_title_and_year(html)
    scan_genre(html)
    scan_poster(html)
    scan_rating(html)
    scan_director(html)
  end

  def scan_genre(html)
    result= []
    #<h5>Genre:</h5>
    #<a href="/Sections/Genres/Action/">Action</a> | <a href="/Sections/Genres/Abenteuer/">Abenteuer</a> | <a href="/Sections/Genres/Drama/">Drama</a> | <a href="/Sections/Genres/Kriegsfilm/">Kriegsfilm</a> <a class="tn15more inline" href="/title/tt0311113/keywords" onClick="(new Image()).src='/rg/title-tease/keywords/images/b.gif?link=/title/tt0311113/keywords';">mehr</a>
    #</div>
    
    # html.scan(/<h5>Genre:<\/h5>(.*?)<\/div>/m) { |m|
    #       $1.scan(/<a href="\/Sections\/Genres\/(.*?)\/">(.*?)<\/a>/) { |m|
    #         result << $1
    #       }
    #     }
    
    html.scan(/<h5>Genre:<\/h5>\n(.*?)\n<\/div>/m) { |m|
      result = $1.split(" | ") 
    }

    #<h5>Genre:</h5>
    # Action | Abenteuer | Drama | Krieg
    # </div>

    @genre=result.collect { |ea|Unicode::normalize_KC(ea)}
    #@genre=result.collect { |ea| CGI.unescapeHtml(ea)}
  end

  def scan_title_and_year(html)
    html.scan(/<title>(?:&#34;)?(.*?)(?:&#34;)? \((\d+)(?:\/I)?\)( \(\w+\))?<\/title>/) { |m|
      @title=$1
      @year=$2
    }
    @title
  end

  def scan_poster(html)
    html.scan(/<a name="poster" .*?<img.*?src="(.*?)"/m) { |m|
      @poster=$1
    }
    @poster
  end

  def scan_rating(html)
    @rating=0.0
    #<b>Nutzer-Bewertung:</b> 
    #<b>7.5/10</b>
    # <small>(<a href="ratings">47,996 Bewertungen
    #html.scan(/Nutzer-Bewertung:<\/b>.*<b>(\d+\.\d+)\/10/m) { |m|
    #  @rating=$1.to_f
    #}
    
    #<div class="meta">
    #<b>7,1/10</b>
    html.scan(/<div class="meta">\n<b>(\d+\,\d+)\/10/m) { |m|
      string = $1 
      @rating=string.sub(",",".").to_f
      puts "rating " + string.to_s + " => " + @rating.to_s
    }
    @rating
  end

  def scan_director(html)
    #<h5>Regisseur:</h5>
    #<a href="/name/nm0001837/">Peter Weir</a><br/>
    #</div>
    html.scan(/<h5>Regisseur:<\/h5>
<a href=".*?">(.*?)<\/a>/m) { |m|
      @director=$1
    }
   @director
  end

  def local_poster_link
    "poster/"+imdbid.to_s+".jpg"
  end

  def poster_filename(db)
    return db.poster_cache+imdbid.to_s+".jpg"
  end
end
