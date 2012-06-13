$LOAD_PATH.unshift(File.expand_path("../../../", __FILE__))
require 'test/unit'
require 'imdb/imdb'

class TC_Imbd_offline < Test::Unit::TestCase
  def setup
    @db=Imdb.new
  end
    
  def test_title_from_filename
    assert_equal("Cast Away",
                 @db.title_from_filename("Cast_Away_2of2.avi"))
    assert_equal("Scary Movie 2", 
                 @db.title_from_filename("Scary_Movie_2_1of5_[en].avi"))
    assert_equal("Taxi",
                 @db.title_from_filename("Taxi_[de].avi"))
    assert_equal("Taxi",
                 @db.title_from_filename("/foo/bar/Taxi_[de].avi"))
    assert_equal("Taxi",
                 @db.title_from_filename("../bar/Taxi_[de].avi"))
    assert_equal("My Fair Lady",
                 @db.title_from_filename("My_Fair_Lady_(1964)_2of2.avi"))
  end
  
  def test_year_from_filename
    assert_equal("1964",
                 @db.year_from_filename("My_Fair_Lady_(1964)_2of2.avi"))
  end

  def test_extract_all_titles
    html='<h2>Popular Results</h2> <p><b>Popular Titles</b> (Displaying 2 Results) <table><tr> <td valign="top"><a href="/rg/photo-find/title-tiny/title/tt0119282/"><img src="http://ia.ec.imdb.com/media/imdb/01/I/95/15/16t.jpg" width="23" height="32" border="0"></a>&nbsp;</td><td align="right" valign="top"><img src="/images/b.gif" width="1" height="6"><br>1.</td><td valign="top"><img src="/images/b.gif" width="1" height="6"><br><a href="/title/tt0119282/">Hercules</a> (1997)</td></tr><tr> <td valign="top"><a href="/rg/photo-find/title-tiny/title/tt0111999/"><img src="http://ia.ec.imdb.com/media/imdb/01/I/52/91/09t.jpg" width="23" height="32" border="0"></a>&nbsp;</td><td align="right" valign="top"><img src="/images/b.gif" width="1" height="6"><br>2.</td><td valign="top"><img src="/images/b.gif" width="1" height="6"><br><a href="/title/tt0111999/">&#34;Hercules: The Legendary Journeys&#34;</a> (1995)<br>&#160;alternativ: <em>"Hercules"</em> - Germany, Norway</td></tr></table> </p>'
    result=@db.extract_all_titles(html)
    assert_equal(result.size,2)
    assert_equal(result[0]["title"],"Hercules")
  end
  
  def test_extract_all_titles_ray
    html='<br><a href="/title/tt0350258/">Ray</a> (2004/I)</td></tr>'
    result=@db.extract_all_titles(html)
    assert_equal(result.size,1)
    assert_equal(result[0]["title"],"Ray")
  end

  def test_extract_popular
    html=File.read("find_daslebend.html")
    popular=@db.extract_popular_titles(html)
    assert(popular != nil)
    assert_equal(popular.size,1)
    assert_equal(popular[0]["title"],"Das Leben der Anderen")    
  end

  def test_extract_other
    html=File.read("find_28daylater.html")
    popular=@db.extract_other_titles(html)
    assert(popular != nil)
    assert_equal(popular.size, 7)
    assert_equal(popular[0]["title"],"28 Days Later...")    
  end

  def test_find_ray
    html=File.read("find_ray.html")
    popular=@db.extract_popular_titles(html)
    assert(popular != nil)
    assert_equal(popular[0]["title"],"Ray")    
  end
  
  def test_himmel_ueber_berlin
     html=File.read("find_himmelberlin.html")
     result=@db.extract_html(html)
     assert(result != nil)
     puts result
     assert_equal(result["title"],"Himmel &#252;ber Berlin, Der")    
   end

  def test_extract_all_titles
    # <a href=\"(:?http:\/\/german\.imdb\.com)?\/title\/(tt\d+).*?>(.*?)<\/a>/m
    html='p><b>Meistgesuchte Titel</b> (1 Ergebnis wird angezeigt)<table><tr>
    <td valign="top"><a href="/title/tt0405094/" onClick="(new Image()).src=\'/rg/photo-find/title-tiny/images/b.gif?link=/title/tt0405094/\';">
    <img src="http://ia.media-imdb.com/images/M/MV5BMTU3NDIzNTk5OF5BMl5BanBnXkFtZTcwMTMzMDA1MQ@@._V1._SX23_SY30_.jpg" width="23" height="32" border="0"></a>&nbsp;</td>
    <td align="right" valign="top"><img src="/images/b.gif" width="1" height="6"><br>1.</td><td valign="top">
    <img src="/images/b.gif" width="1" height="6"><br>
    <a href="/title/tt0405094/">Leben der Anderen, Das</a> (2006)<br>&#160;alternativ: <em>"Leben der Anderen - Die Sonate vom guten Menschen, Das"</em> - Germany <em>(working title)</em>
    </td></tr></table'
    popular= @db.extract_all_titles(html)
    assert(popular != nil)
    assert_equal(popular.size, 1)
    assert_equal(popular[0]["title"], "Leben der Anderen, Das")       
    assert_equal(popular[0]["year"], "2006")       
  end

  def test_extract_all_titles2
    html = '<a href="/title/tt0289043/">28 Days Later...</a> (2002)<br>'
    titles= @db.extract_all_titles(html)
    assert(titles != nil)
    assert_equal(titles.size, 1)
    assert_equal(titles[0]["title"], "28 Days Later...")       
    assert_equal(titles[0]["year"], "2002")
  end

  def test_extract_all_titles3
    html = '<p><b>Titel (näherungsweise Übereinstimmung)</b> (7 Ergebnisse werden angezeigt)<table><tr> 
    <td valign="top"><a href="/title/tt0289043/" onClick="(new Image()).src=\'/rg/photo-find/title-tiny/images/b.gif?link=/title/tt0289043/\';">
    <img src="http://ia.media-imdb.com/images/M/MV5BNDgxODQ3ODY2NV5BMl5BanBnXkFtZTcwODg3MDYyMQ@@._V1._SX23_SY30_.jpg" width="23" height="32" border="0"></a>&nbsp;</td>
    <td align="right" valign="top">
    <img src="/images/b.gif" width="1" height="6"><br>1.</td><td valign="top"><img src="/images/b.gif" width="1" height="6"><br>
    <a href="/title/tt0289043/">28 Days Later...</a> (2002)<br>
    &#160;alternativ: <em>"28 Days Later"</em> - UK <em>(closing credits title)</em><br>
    &#160;alternativ: <em>"29 Days Later"</em> - USA <em>(longer version)</em></td></tr>
    <tr> <td valign="top"><a href="/title/tt0339542/" onClick="(new Image()).src=\'/rg/photo-find/title-tiny/images/b.gif?link=/title/tt0339542/\';">
    <img src="http://ia.media-imdb.com/images/M/MV5BMTYzNjQ0NjAyM15BMl5BanBnXkFtZTcwOTAwNjAyMQ@@._V1._SX23_SY30_.jpg" width="23" height="32" border="0"></a>&nbsp;</td><td align="right" valign="top"><img src="/images/b.gif" width="1" height="6"><br>2.</td>
    <td valign="top"><img src="/images/b.gif" width="1" height="6"><br><a href="/title/tt0339542/">Pure Rage: The Making of \'28 Days Later\'</a> (2002) (TV)</td></tr>
    <tr> <td valign="top"><img src="/images/b.gif" alt="" width="23" height="1"></td>
    <td align="right" valign="top">3.</td><td valign="top"><a href="/title/tt1045796/">28 Days Later: The Aftermath (Chapter 1)</a> (2007) (V)</td></tr>
    <tr> <td valign="top"><img src="/images/b.gif" alt="" width="23" height="1"></td>
    <td align="right" valign="top">4.</td><td valign="top"><a href="/title/tt1132131/">28 Days Later: The Aftermath (Chapter 3) - Decimation</a> (2007) (V)</td></tr>
    <tr> <td valign="top"><img src="/images/b.gif" alt="" width="23" height="1"></td><td align="right" valign="top">5.</td>
    <td valign="top"><a href="/title/tt0428194/">6 Years &#38; 364 1/2 Days Later</a> (2003)</td></tr><tr> <td valign="top"><img src="/images/b.gif" alt="" width="23" height="1"></td><td align="right" valign="top">6.</td><td valign="top"><a href="/title/tt0973778/">2 Days Later with Jools Holland</a> (1999) (TV)</td>
    </tr><tr> <td valign="top"><img src="/images/b.gif" alt="" width="23" height="1"></td>
    <td align="right" valign="top">7.</td><td valign="top"><a href="/title/tt0855752/">Chand rooz ba\'d...</a> (2006)<br>&#160;alternativ: <em>"A Few Days Later..."</em> - <em>(English title)</em><br>
    &#160;alternativ: <em>"A Few Days Later"</em> - Canada <em>(English title)</em> <em>(festival title)</em></td></tr></table>'
    titles= @db.extract_all_titles(html)
    assert(titles != nil)
    assert_equal(titles.size, 7)
    assert_equal(titles[0]["title"], "28 Days Later...")       
    assert_equal(titles[0]["year"], "2002")
  end
  
  def test_extract_all_titles4
    html ='<table><tr> 
    <td valign="top"><a href="/title/tt0405094/" onClick="(new Image()).src=\'/rg/find-tiny-photo-1/title_popular/images/b.gif?link=/title/tt0405094/\';"><img src="http://ia.media-imdb.com/images/M/MV5BMTU3NDIzNTk5OF5BMl5BanBnXkFtZTcwMTMzMDA1MQ@@._V1._SY30_SX23_.jpg" width="23" height="32" border="0"></a>&nbsp;</td>
    <td align="right" valign="top"><img src="/images/b.gif" width="1" height="6"><br>1.</td><td valign="top"><img src="/images/b.gif" width="1" height="6"><br><a href="/title/tt0405094/" onclick="(new Image()).src=\'/rg/find-title-1/title_popular/images/b.gif?link=/title/tt0405094/\';">Das Leben der Anderen</a> (2006)<br>&#160;Auch bekannt als: <em>"Das Leben der Anderen - Die Sonate vom guten Menschen"</em> - Deutschland <em>(Arbeitstitel)</em></td></tr></table>'
    titles= @db.extract_all_titles(html)
    assert(titles != nil)
    assert_equal(titles.size, 1)
    assert_equal(titles[0]["title"], "Das Leben der Anderen")
    assert_equal(titles[0]["id"], "tt0405094")
  end
  
  def test_extract_html
    html = File.read("find_spurdersteine.html")
    result=@db.extract_html(html)
    assert(result != nil)
    assert_equal(result["title"],"Spur der Steine")
    assert_equal(result["id"],"tt0061017")
     assert_equal(result["year"],"1966")   
  end


  

  def test_scan
    html=File.read("scan.html")
  end
end
