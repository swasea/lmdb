$LOAD_PATH.unshift(File.expand_path("../../../", __FILE__))
require 'test/unit'
require 'imdb/imdb'
require 'lmdb/localmoviedb'

class TC_LocalMovieDB < Test::Unit::TestCase

  def setup
    @db = LocalMovieDB.new
    @db.confpath = "./db/"
    @db.setup_paths  
    @db.setup()
    @movie = @db.movies["tt0311113"]
    @html=@db.load_imdb_html(@movie)

    @movie_yellow = @db.movies["tt0063823"]
    @html_yellow=   @db.load_imdb_html(@movie_yellow)

  end
  
  #def teardown
  #end
  
  def test_movie_scan_genre
    assert_equal(@movie.scan_genre(@html), 
                 ["Action", "Abenteuer", "Drama", "Krieg"])
  end  

  def test_movie_scan_poster
    assert_equal(@movie.scan_poster(@html), 
                 "http://ia.media-imdb.com/images/M/MV5BMTI0NjE1NDY2OF5BMl5BanBnXkFtZTcwNjY2NTUyMQ@@._V1._SX100_SY140_.jpg")
  end  
  
  def test_movie_scan_title_and_year
    
    html='<title>Pirates of Silicon Valley (1999) (TV)</title>'
    assert_equal(Movie.new.scan_title_and_year(html), 
                 "Pirates of Silicon Valley")
  end  

  def test_movie_scan_title_and_year_2
    html='<title>&#34;The Water Margin&#34; (1977) (mini)</title>'
    assert_equal(Movie.new.scan_title_and_year(html), 
                 "The Water Margin")
  end  

  def test_movie_scan_title_and_year_3
    html='<title>The Beach (2000/I)</title>'
    movie= Movie.new
    movie.scan_title_and_year(html)
    assert_equal(movie.title, "The Beach")
    assert_equal(movie.year, "2000")

  end  

  def test_movie_scan_poster_yellow
    assert_equal(@movie_yellow.scan_poster(@html_yellow), 
                 "http://ia.media-imdb.com/images/M/MV5BMTIzMDAzNjE2OF5BMl5BanBnXkFtZTcwMzI2OTMyMQ@@._V1._SX95_SY140_.jpg")
  end  
  
  def test_movie_scan_rating
    assert_equal(@movie.scan_rating(@html),7.5)
  end  

  def test_movie_scan_director
    assert_equal(@movie.scan_director(@html),"Peter Weir")
  end  
  
end
