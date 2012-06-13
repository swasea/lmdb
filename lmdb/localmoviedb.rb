#!/usr/bin/env ruby 
$LOAD_PATH.unshift(File.expand_path("../../", __FILE__))

require 'optparse'
require 'optparse/time'
require 'ostruct'

require 'yaml'
# require 'gtk2' # for glib
require 'ftools'
require 'set'
require 'iconv'

require 'imdb/imdb' 
require 'lmdb/media'
require 'lmdb/movie'
require 'lmdb/moviefile'

class LocalMovieDB

  attr_accessor :movies
  attr_accessor :files
  attr_accessor :media
  attr_accessor :poster_cache
  attr_accessor :confpath

  # initialize

  def initialize
    @options= OpenStruct.new
    @movies={}
    @files={}
    @media={}
    @overrides={}
    @ignore=Set.new

    @imdb= Imdb.new
    @args=ARGV

    # @confdir=".localmdb"
    # @confpath=GLib.home_dir+"/"+@confdir+"/"
    @confpath="db/"
  end

  def setup_paths
    @movies_filename=    confpath+"movies.yaml"
    @files_filename=     confpath+"files.yaml"
    @overrides_filename= confpath+"override.yaml"
    @ignore_filename=    confpath+"ignore.yaml"
    @media_filename=     confpath+"media.yaml"
    @html_cache=         confpath+"/html/"
    @poster_cache=       confpath+"/poster/"
  end

  def setup
    p "setup"
    setup_paths
    load_yaml_files()
    update_dynamic_media()
  end
  
  #
  # persisence
  # 

  def load_from(filename, fallback)
    file = File.open(filename)
    return YAML::load(file)
  rescue
    STDERR.puts "could not load " + filename.to_s
    return fallback
  end

  def store_object_to(object, filename)
    file = File.new(filename, 'w') 
    file.write(object.to_yaml)
    file.close()
    rescue
      STDERR.puts "could not store " + filename.to_s
    return nil
  end
  
  def load_yaml_files()
    p "++ load yam ++"

    if(File.exists?(@files_filename))
      @files=     load_from(@files_filename,     Hash.new)
      @movies=    load_from(@movies_filename,    Hash.new)
      @overrides= load_from(@overrides_filename, Hash.new)
      @ignore=    load_from(@ignore_filename,    Set.new)

      @media=    load_from(@media_filename,    Hash.new)
      @media.each_value{|medium| medium.load}
    else
      STDERR.puts "" + @files_filename.to_s + " does not exist"
    end
  end

  def store_yaml_files()
    Dir.mkdir(confpath) if not File.exist? confpath

    store_object_to(@files,     @files_filename)
    store_object_to(@movies,    @movies_filename)
    store_object_to(@overrides, @overrides_filename)
    store_object_to(@ignore,    @ignore_filename)

    @media.each_value{|medium| medium.clear}
    store_object_to(@media,    @media_filename)
  end

  def dynamic_media
    (@media.collect{ |key, medium| medium}).select {|medium| medium.dynamic?}
  end

  def update_dynamic_media
    dynamic_media.each { | medium |
      puts "update " + medium.to_s
      old_filenames= filenames_of_media(medium.name)
      new_filenames= (medium.collect {|filename | filename}).to_set
      
      to_remove= (old_filenames - new_filenames)
      to_add= (new_filenames - old_filenames)

      puts "to remove:" 
      to_remove.each { |each | puts "  "+ each}
      puts "to add:" 
      to_add.each { |each | puts "  "+ each}

      to_remove.each { |eachFileName |
        moviefile= @files[eachFileName]
        moviefile.media_ids.delete(medium.name)
        if moviefile.media_ids.empty?
          @files.delete(eachFileName)
        end
      }
      to_add.each { |eachFileName| 
        movie_file= add_file(eachFileName)
        movie_file.media_ids.add(medium.name)
      }
    }
  end

  # imdb cache

  def id_is_in_cache?(imdb_id)
    filename=@html_cache+imdb_id.to_s+".html"
    return File.exists?(filename)
  end

  def load_file(filename)
    if(File.exists?(filename)) then
      begin
        return File.read(filename)
      rescue 
        puts "ERROR: reading" + filename.to_s
      end
    end
    return nil
  end
  
  def load_imdb_html(movie)
    load_imdb_html_id(movie.imdbid)
  end

  def load_imdb_html_id(imdb_id)
    load_file(@html_cache+imdb_id.to_s+".html")
  end
   
  def store_imdb_html(movie,html)
    Dir.mkdir(@html_cache) if not File.exist? @html_cache
    filename=@html_cache+movie.imdbid+".html"
    begin
      File.open(filename,"w"){|file|
        file.write(html)
      }
    rescue
      puts "ERROR: writing" + filename.to_s
    end
  end

  def store_imdb_poster(movie, poster)
  Dir.mkdir(@poster_cache) if not File.exist? @poster_cache
   filename=movie.poster_filename(self)
    begin
      File.open(filename,"w"){|file|
        file.write(poster)
      }
    rescue
      puts "ERROR: writing" + filename.to_s
    end
  end


  #
  # accessors
  # 

  def all_genres
    return (movies.collect {|id, movie| 
      movie.genre}).flatten.reject{ |each| each == nil}.to_set.sort
  end

  def all_movies
    return @movies.collect { |id, movie| movie}
  end
  
  def all_years
    return used_movies.collect { |movie| movie.year}.select{|e| e}.to_set
  end

  def all_files
    return @files.reject{ |key, file| ignore_file?(key)}.
      collect {|key, file| file}
  end
  
  def all_media
    
  end

  def used_movies
    apply_overrides
    return @files.select{|filename, file| not ignore_file?(filename)}.
      collect { |filename, file| @movies[file.movie_id]}.
      reject{ |each| each == nil}.to_set 
  end

  def movies_of_genre(genre)
    return used_movies.select { |each| each.genre && each.genre.include?(genre)}
  end

  def movies_of_year(year)
    return used_movies.select { |each| each.year == year}
  end

  def file_titles
    return @files.collect{|key, value| value.title}.to_set
  end

  def filenames_of_media(media_id)
    files_of_media= @files.select {|key, value| 
      value.media_ids.include?(media_id)}
    return files_of_media.collect{|key, value| value.file}.to_set
  end

  def movie_titles
    return @movies.collect{| key, value| value.title}.to_set
  end
  
  def movie_files
    return @movie_files_cache if @movie_files_cache
    @movie_files_cache={}
    @files.each { |key, value|  
      if not @movie_files_cache[value.movie_id]
        @movie_files_cache[value.movie_id]=[]
      end
      @movie_files_cache[value.movie_id] << value
    }
    return @movie_files_cache
  end

  #
  # testing
  #

  def ignore_file?(filename)
    @ignore.each { |each|
      if filename =~ Regexp.new(each)
        return true
      end
    }
    return false
  end
  
  #
  # parse options
  #

  def parse_options(args)
    args_size= args.size    
    opts= OptionParser.new do |opts|
      opts.banner= "Usage: local_mdb.rb [options] [files]"
      opts.separator ""
      opts.separator "Specific options:"
      opts.on_tail("-h", "--help", "Show this message") do
        STDERR.puts opts
        exit
      end
      opts.on_tail("--add", "add files") do
        @options.add_files= true
      end
      opts.on_tail("--add-media", "add media") do
        @options.add_media= true
      end
      opts.on_tail("--add-dynamic-media directory", "add dynamic media") do |root|
        @options.add_dynamic_media= root
      end
      opts.on_tail("--remove-media", "remove media") do
        @options.remove_media= true
      end
      opts.on_tail("--update-media", "update media") do
        @options.update_media= true
      end
      opts.on_tail("-g", "--generate-index", "generate index") do
        @options.generate_index= true
      end
      opts.on_tail("-i", "--ignore", "ignore movies (id)") do
        @options.ignore_movies= true
      end
      opts.on_tail("--generate-meta", "generate meta info") do
        @options.generate_meta= true
      end
      opts.on_tail("-l", "--list-all", "list files and movies") do
        @options.list_files= true
        @options.list_movies= true
        @options.list_overrides= true
        @options.list_ignore= true
      end
      opts.on_tail("-f", "--force", "force actions") do
        @options.force= true
      end
      opts.on_tail("--fix-overrides", "fix overrides") do
        @options.fix_overrides= true
      end
      opts.on_tail("--list-movies", "list movies") do
        @options.list_movies= true
      end
      opts.on_tail("--list-media", "list media") do
        @options.list_media= true
      end
      opts.on_tail("-t", "--test", "only test") do
        @options.test= true
      end
      opts.on_tail("-u", "--update", "update from imdb") do
        @options.update= true
      end
      opts.on_tail("-p", "--update-poster", "update from imdb") do
        @options.update_poster= true
      end
      opts.on_tail("-s", "--scan", "scan imdb entries") do
        @options.scan= true
      end
      opts.on("-o", "--override id", "override movie_id for filenames") do |id |
        @options.override_movie_id=id
      end
      opts.on("-c", "--confpath path", "set confpath") do | path |
        @options.confpath= path
      end
      opts.on_tail("--medium-prefix prefix", "medium prefix") do | prefix |
        @options.medium_prefix= prefix
      end
      opts.on_tail("-r", "--recursive", "parse directories recursively") do
        @options.recursive= true
      end
    end
    
    opts.parse!(args)
    
    if args_size == 0
      STDERR.puts opts
      exit
    end

    @command_arg_files= []
    ARGV.each { |f|
      @command_arg_files.push(f)
    }
  end  


  #
  # commands
  #

  def add_file(file)
    if not @files[file] or @options.force
      puts "add file " + File.basename(file) 
      movie_file= MovieFile.new
      movie_file.file=file
      return @files[movie_file.file]=movie_file
    else
      return @files[file]
    end
  end  

  def add_media(files)
    files.each {|filename|
      medium=Medium::from_file(filename)
      puts "  == adding "+medium.id+" =="
      @media[medium.name]=medium
      medium.each { |node|
        if node.path.movie? 
          movie_file= add_file(node.path)
          movie_file.media_ids.add(medium.name)
        end

        if @options.medium_prefix
          medium.prefix=@options.medium_prefix
        end
      }
    }
  end

  def add_dynamic_media(directory)
    puts "add dynamic media "+ directory
    medium= DynamicMedium::from_dir(directory)
    @media[medium.name]=medium
  end

  def remove_media(media_ids)
    media_ids.each { |medium_path|
      medium_id = File.basename(medium_path, ".cdrom")
      p "remove media " + medium_id.to_s
      @media.delete(medium_id)
      media_files=@files.select { |key, file| file.media_ids.include?(medium_id)}
      media_files.each{ |key, file|
        p "remove file " + file.to_s
        file.media_ids.delete(medium_id)
        if file.media_ids.empty?
          puts "remove "+file.to_s
          @files.delete(key)
        end
      }
    }
  end
  
  def add_files(files)
    files.each{ |file|
      if File.directory?(file) and @options.recursive
        add_files(Dir.glob(file+"/*"))
      else
        if /\.cdrom$/.match(file) then
          add_cdrom_file(file)
        else
          if file.movie?
            moviefile= add_file(file) 
            moviefile.media_ids.add("default")
          end
        end
      end
    }
  end

  def override_movie_id(patterns, override_movie_id)
    puts " == overiding  with " + override_movie_id + " =="
    movie= @movies[override_movie_id]
    if not movie or @options.force
      imdb=Imdb.new
      movie=imdb.find_movie(override_movie_id)
      if movie
        puts " found " + movie.to_s
        update_imdb_cache_for(movie)
        @movies[movie.imdbid]=movie 
      end
    end
    if movie then
      patterns.each { |file_pattern|
        if file_pattern.size < 5 
          puts "Warning: pattern (" + file_pattern + ") is to short"
        else
          re = Regexp.new(file_pattern)
          @files.each{ |key, file| 
            if key =~ re
              puts "  overriding: " + key
              @overrides[key]=movie.imdbid
            end
          }
        end
      }      
    end
  end
  
  def add_cdrom_file(file)
    node = Node::from_lslist(File.read(file))
    p node.file_list
    
    node.file_list.each {|file| 
      add_file(file) if file.movie?
    }
    
  end

  #
  # find movies in imdb for each file
  #

  def update()
    @titles_id = {}
    db=Imdb.new
    
    update_files = all_files.select {|file| not file.movie_id}
    
    puts "  = update files = "
    update_files.sort.each{ |each|
      puts "  " + each.to_s
    }
    update_titles = update_files.collect {|file| file.title}.to_set
    update_titles.sort.each { |title|
      puts "searching %s: " % title
      # puts "   " + CGI.escape(title)
      if not @options.test
        time=Time.now
        movie=db.find_movie(Iconv.new('utf-8','iso-8859-15').iconv(title))
        if movie then
          @titles_id[title]=movie 
          update_file_movieid(title, movie.imdbid)      
          puts "found \"%s\" in %ss" % 
            [@titles_id[title].to_s,(Time.now - time).to_s] 
        end
      end
    }

    @titles_id.each { |key, value|
        @movies[value.imdbid]=value
    }
  end

  def update_imdb_cache_for(movie)
    if not movie.imdbid then
      puts "could not download " + movie.to_s +  " because id is missing‚"
      return 
    end
    if not id_is_in_cache?(movie.imdbid) or @options.force then
      puts "downloading "+movie.to_s
      html=@imdb.get_imdb_title(movie.imdbid)
      store_imdb_html(movie, html)
    end
  end
  
  def update_imdb_cache()
    @movies.each { |id, movie| 
      update_imdb_cache_for(movie)
    }
  end

  def scan_imdb_entries()
    puts "== scan entries =="
    @movies.each { |id, movie| 
      if (not movie.scaned? or @options.force) and movie.imdbid
        html=load_imdb_html(movie)
        movie.scan(html) 
        puts "scanned " + movie.to_s
      end
    }
  end

  def update_imdb_poster()
    puts "== update poster =="
    imdb=Imdb.new
    movies.each {|id, movie|
      if movie.poster
        if not File.exists?(movie.poster_filename(self))
          puts "download "+movie.poster.to_s
          begin
            image=imdb.fetch(movie.poster).body
            store_imdb_poster(movie, image)
          rescue
            puts "ERROR: downloading " + movie.poster.to_s
          end

        end
      end
    }
    
  end

  def update_file_movieid(title, imdb_id)
    (@files.select { |key, value| value.title == title}).each { |key, value| 
      value.movie_id= imdb_id
    }
  end

  #
  # html generation
  #

  def movies_sort_best(movies)
    movies.sort{|a,b| b.rating <=> a.rating }
  end

  def movies_sort_year(movies)
    movies.sort.sort{|a,b| 
      b.year.to_s <=> a.year.to_s
    } 
  end

  def movies_sort_director(movies)
    movies.sort{|a,b| a.director.to_s <=> b.director.to_s}
  end

  def generate_index
    File.open("imdb_navigator.html", "w") { |file|
      file.puts '
<html>
<head>
 <title>LocalMDB</title>
 <link rel="stylesheet" type="text/css" href="imdb_style.css">
 <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body class="navigator">'

      file.puts '<h1>LocalMDB</h1>'
      
      # all 
      file.puts '<h2><a href="imdb_all.html" target="main">all ('+used_movies.size.to_s+')</a></h2>'
      generate_index_of_movies("imdb_all", used_movies.sort)

      # best
      file.puts '<h2><a href="imdb_best.html" target="main">best</a></h2>'
      generate_index_of_movies("imdb_best", 
                               movies_sort_best(used_movies))
      

      # director
      file.puts '<h2><a href="imdb_director.html" target="main">director</a></h2>'
      generate_index_of_movies("imdb_director", 
                               movies_sort_director(used_movies))

      
      # generate_index_by_genre
      file.puts "<h2>genre</h2>"
      all_genres.each { |eachGenre|
        sorted_movies= movies_sort_best(movies_of_genre(eachGenre))
        if sorted_movies.size > 0
          generate_index_of_movies("imdb_genre_"+eachGenre,sorted_movies)
          file.puts '<div class="genre_link">'+
            '<a href="imdb_genre_'+eachGenre+'.html" target="main">'+eachGenre+
            ' ('+sorted_movies.size.to_s+')</div>'
        end
      }    
        
      # year
      file.puts '<h2><a href="imdb_year.html" target="main">year</a></h2>'
      generate_index_of_movies("imdb_year", movies_sort_best(used_movies))
      movie_collections=[]
      all_years.sort{|a,b| b <=> a}.each { |each|
        some_movies= movies_of_year(each)
        movie_collections << [each, some_movies]
        file.puts '<div class="year_link">'+
        '<a href="imdb_year.html#',each,'" target="main">'+each+
        ' ('+some_movies.size.to_s+')</div>'
        
      }
      generate_index_of_movie_collections("imdb_year",movie_collections)

      file.puts "</body></html>"
    }
  end
  
  def generate_index_of_movies(title, movies)
    generate_index_of_movie_collections(title,[["default",movies]])
  end

  def generate_index_of_movie_collections(title,movie_collections)
    Dir.mkdir("poster") if not File.exist? "poster"
    
    filename = "%s.html" % title
    File.open(filename, "w") { |file|
      file.puts '
<html>
<head>
 <title>'+title+'</title>
 <link rel="stylesheet" type="text/css" href="imdb_style.css">
 <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body>'
      file.puts "<h1>%s</h1>" % title
      movie_collections.each{ |key, movies| 
        file.puts '<div class="collection" id="'+key+'">' 
        movies.each { |movie|
          file.puts movie.html_short_entry(self)
        }
        file.puts "</div>"
      }
      file.puts "</body></html>"
    }    
  end

  #
  # commands
  #
  
  def apply_overrides
    @overrides.each { |filename, id |
      @files[filename].movie_id=id if @files[filename]
    }
  end


  def fix_overrides
    @overrides.clone.each { |filename, id |
      override_movie_id(File.basename(filename), id)
    }
    
  end

  def update_media
    puts "== update media == "
    @files.delete_if { |key, file| 
      if file.media_ids.empty? 
        puts " remove "+file.to_s
        true
      end
    }
  end

  
  def generate_meta
    puts "== meta data =="
    puts "  genre: " 
    all_genres.each{|each| 
      puts "   " + each.to_s + " " + movies_of_genre(each).size.to_s

    }
  end

  def pre_setup
    parse_options(@args)
    
    if @options.confpath
      @confpath=@options.confpath + "/"
      setup_paths
    end

  end


  #
  # run
  #

  def run
    
    #
    # add files / media
    #

    if @options.add_files 
      add_files(@command_arg_files)
    end
    if @options.add_media
      add_media(@command_arg_files)
    end
    if @options.remove_media 
      remove_media(@command_arg_files)
    end
    if @options.update_media
      update_media
    end

    if @options.ignore_movies
      puts "-- ignore movies -- "
      @command_arg_files.each { |each|
        puts each
      }
      @ignore.merge(@command_arg_files)
    end

    if @options.add_dynamic_media
      add_dynamic_media(@options.add_dynamic_media)
    end
    
    #
    # list db content
    #

    if @options.list_files 
      puts ""
      puts "== Files =="
      @files.sort.each { |key, file| puts file}
    end
    if @options.list_movies 
      puts ""
      puts "== Movies =="
      @movies.each { |key, movie|
        puts movie
      }
    end
    if @options.list_media 
      puts ""
      puts "== media =="
      @media.each { |key, medium|
        puts medium
      }
    end
    if @options.list_medium 
      puts ""
      puts "== medium =="
      if medium= @media[@options.list_medium] 
        puts medium.text
      end
    end
    if @options.list_overrides 
      puts "== overrides =="
      @overrides.sort.each { |file, movie_id| puts file + " => " + movie_id}
    end
    if @options.list_ignore 
      puts ""
      puts "== Ignore =="
      @ignore.each { |each|
        puts each
      }
    end
    
    #
    # correct entries
    #

    if @options.override_movie_id
      override_movie_id(@command_arg_files, @options.override_movie_id.to_s)
      apply_overrides
    end

    if @options.fix_overrides
      puts "== fix overrides =="
      fix_overrides
    end

    #
    # gather information
    #

    if @options.update 
      puts "== update from imdb =="
      update()
      update_imdb_cache()
    end
    if @options.scan 
      scan_imdb_entries()
    end
    if @options.update_poster
      update_imdb_poster()
    end

    #
    # generate report
    #

    if @options.generate_meta
      generate_meta  
    end
    if @options.generate_index 
      generate_index
    end

    # 
    # save and quit
    #
    if not @options.test
      store_yaml_files()
    end
  end
  
  def LocalMovieDB::run(args)
    ldb = LocalMovieDB.new
    ldb.pre_setup
    ldb.setup
    ldb.run
  end
end

def emacs_test
  @db = LocalMovieDB.new
  @db.load_yaml_files()
  @movie = @db.movies["tt0311113"]
  @db.load_imdb_html(@movie)
  @html=@db.load_imdb_html(@movie)

  nil
end

END {
  LocalMovieDB.run(ARGV)
}
