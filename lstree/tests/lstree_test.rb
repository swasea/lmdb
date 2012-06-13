
require 'test/unit'
require 'lstree'

include LsTree


class TC_lstree < Test::Unit::TestCase
  def setup

    @ls_data1 = "foobar
foo.avi
bar.mpg"

    @ls_data2 = "foobar/:
bar.mpg
foo.avi"

    @ls_data3 = "cdrom/:
foobar
foobar2

cdrom/foobar:
bar1.mpg
foo1.avi

cdrom/foobar2:
bar2.mpg
foo2.avi
"

  end
  
  #def teardown
  #end


  def test_from_lslist1
    node = Node::from_lslist(@ls_data1)
    
    assert_equal(3,node.children.size)

    puts node.to_s
  end


  def test_from_lslist2
    node = Node::from_lslist(@ls_data2)
    
    assert_equal(3,node.children.size)

    puts node.to_s
  end
  

  def test_from_lslist3
    node = Node::from_lslist(@ls_data3)
    
    assert_equal(1,node.children.size)
    assert_equal("2",node.to_s)
  end


end
