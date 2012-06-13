#!/usr/bin/ruby


require 'net/http'
require 'uri'
require 'set'
require 'cgi'

class Movie
  attr_accessor :title
  attr_accessor :year
  attr_accessor :imdbid

  def initialize
  end

  def tags= new_tags
    @imdbid=   new_tags['id']
    @title=new_tags['title']
    @year= new_tags['year']
  end

  def to_s
    "%s %s %s" % [imdbid, title, year]
  end
end

class Imdb

  def initialize
    @uri_base="http://german.imdb.com/find?s=all&q=" #;site=aka
    @uri_base_title="http://german.imdb.com/title/"

    @connection=Net::HTTP.new(@host, 80)
    @cache_find={}
    @cache_imdb=true
  end  

  def fetch(uri_str, limit = 20)
    p "fetch("+uri_str.to_s+")"
    # You should choose better exception.
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0
    
    response = Net::HTTP.get_response(URI.parse(uri_str))
    case response
    when Net::HTTPSuccess     then response
    when Net::HTTPRedirection then fetch(response['location'], limit - 1)
      
    else
      response.error!
    end
  end

  def get_imdb_title(imdbid)
    begin
      result = fetch(@uri_base_title + imdbid.to_s+"/").body
    rescue
      STDERR.puts "Error get_imdb_title(" + imdbid.to_s + ")"
      result = ""
    end
    return result
  end

  def get_http_find(title)
    # p "get_http_find("+title.to_s+")"
    if title == 0 
      return "error"
    else
      return fetch(@uri_base + CGI::escape(title.to_s)).body
    end
  end

  def return_find_result(title, result)
    return result
  end

  def find(title)
    puts "find " + title
    if @cache_imdb and @cache_find[title]
      return @cache_find[title]
    end
    text= get_http_find(title)
    if text =~ /<title>IMDb Suche<\/title>/
      result= extract_popular_titles(text)
      puts "found popular titles  " if result
      if not result
        result= extract_other_titles(text)
        puts "found other titles  " if result
      end
      if result
        first_result= result[0]
      else 
        first_result=nil  # nothing found
      end
    else
      puts "found direct match"
      first_result= extract_html(text)
    end

    if @cache_imdb 
      return @cache_find[title]=first_result
    end
    return first_result
  rescue
    return nil
  end
  
  def find_movie(title)
    begin
      result =find(title)
    rescue
      result = nil
    end
    if result
      movie = Movie.new()
      movie.tags= result
      return movie
    else
      return nil
    end
  end

  def result_to_s(result)
    return "%s %s %s" % [result['id'], result['title'], result['year']]
  end

  def print_popular(title)
    res= find_popular(title)
    if res
      if res.empty?
        res= find(title)
      end
      res.each { |movie|
        puts "%s %s %s " % [movie['id'], movie['title'], movie['year']]
      }
    end
  end

  def extract_popular_titles(html)
    html.scan(/(<p><b>Meistgesuchte Titel.*?<\/table)/) { |m|
      return extract_all_titles($1)
    }
    return nil
  end

  def extract_other_titles(html)
    html.scan(/(<p><b>Titel \(.*?\)<\/b>.*?<\/table>)/m) { |m|
      puts "OTHER:" + html.to_s
      return extract_all_titles($1)
    }
    return nil
  end


  def extract_html(html)
    result={}
    html.scan(/value="i18n\/title\/(tt\d+)\//) { |m|
      result['id']=$1
    }
    
    html.scan(/<title>(.*?) \((\d+)\)( \(.*?\))?<\/title>/) { |m|
      result['title']=$1
      result['year']=$2
    }
    return result
  end
  

  def extract_all_titles(html)
    # puts "extract_all_titles("+html+")"
    result = []
    # <a href=\"(:?http:\/\/german\.imdb\.com)?\/title\/(tt\d+).*?>(.*?)<\/a>/m
    # <a href="/title/tt0289043/">28 Days Later...</a> (2002)<br>
    #<br><a href="/title/tt0350258/">Ray</a> (2004/I)</td></tr>
    
    # <a href="/title/tt0405094/" onclick="(new Image()).src=\'/rg/find-title-1/title_popular/images/b.gif?link=/title/tt0405094/\';">Das Leben der Anderen</a> (2006)<br>
    
    html.scan(/<a href=\"\/title\/(tt\d+)\/\"[^<]*?>(?!<img)([^<]*?)<\/a> \((\d\d\d\d)(\/.)?\)/m){ |m|
      puts "match: " + m.to_s
      movie={}
      movie['id']=$1
      movie['title']=$2
      movie['year']=$3
      puts "Movie:" + m.to_s
      result.push(movie)
    }
    return result

  end
  
  def Imdb::scan_filename(filename)
    result = {}
    File.basename(filename).scan(/^(.*?)                # title
                    (_\((\d+)\))?                       # _(1984)
                    (_\d+((of)|(von))\d+)?              # _1of2  
                    (_part\d)?                          # _part1
                    (_\[.*\])?                          # _[tags]
                    (\.(...))?$/x) { |m|                # .avi 
      result["title"]=$1
      result["year"]=$3
      result["title"].gsub!("_"," ")
      
    }
    return result
                     
  end
  
  def title_from_filename(filename)
    return Imdb::scan_filename(filename)['title']
  end

  def year_from_filename(filename)
    return Imdb::scan_filename(filename)['year']
  end

  def Imdb::run(args)
    db=Imdb.new
    movie_set = (args.collect { |filename| 
                   scan = Imdb::scan_filename(filename)
                   result = scan['title']
                   if scan['year']
                     result += " (" +scan['year'] + ")"
                   end
                   result
                 }).to_set
    movie_set.each { |title|
      puts "searching %s:\t %s" % [title, db.find_movie(title).to_s]
                                                       
    }
  end
end
