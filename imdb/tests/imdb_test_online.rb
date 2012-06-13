$LOAD_PATH.unshift(File.expand_path("../../../", __FILE__))
require 'test/unit'
require 'imdb/imdb'

class TC_Imbd < Test::Unit::TestCase
  def setup
    @db=Imdb.new
  end
  
  #def teardown
  #end
  
  def test_find
    assert_equal(@db.find("Hercules"),
                 {"title"=>"Hercules", "id"=>"tt0119282", "year"=>"1997"})
    assert_equal(@db.find("Buena Vista Social Club"),
                 {"title"=>"Buena Vista Social Club", 
                   "id"=>"tt0186508", "year"=>"1999"})

    assert_equal(@db.find("zorkzork123235"),nil)
  end

  def test_find_2
    movie= @db.find_movie("Viel Lärm Um Nichts")
    assert_equal(movie.id,"tt0107616")
    assert_equal(movie.title,"Much Ado About Nothing")
  end



  def test_run
    Imdb::run(["My Fair Lady (1964)", "/foo/bar/afasdfasdf.avi"])
  end
end
