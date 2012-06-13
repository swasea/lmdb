$LOAD_PATH.unshift(File.expand_path("../../../", __FILE__))
require 'test/unit'
require 'lmdb/movie'

class TC_LocalMovieDB < Test::Unit::TestCase
  
  def test_scan_from_db
    html=File.read("db/html/tt0311113.html")
    movie= Movie.new
    movie.scan(html)
    assert_equal(movie.title,"Master &#38; Commander - Bis ans Ende der Welt")
    assert_equal(movie.year,"2003")
    assert_equal(movie.genre, ["Action", "Abenteuer", "Drama", "Krieg"])
    assert_equal(movie.director,"Peter Weir")
    assert_equal(movie.rating, 7,0)
    assert(movie.poster.match("http://ia.media-imdb.com/"))
  end
end
