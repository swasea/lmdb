#!/usr/bin/ruby

"converts file of the  'ls -R output' to a data structure.
and pretty prints it"


class Node
  attr_accessor :name
  attr_accessor :children


  def initialize(name)
    @name=name
    @children=[]
  end

  def Node::from_lslist(buffer)

    node= Node.new("")

    buffer.scan(/(.*?):(.*?)\n\n/m) { |m| 
      node.parse_head_tail($1, $2)
    }
    return node
  end

  def path_to_list(path)
    result=[]
    path.scan(/(.+?)(\/|$)/){ |m|
      result.push($1)
    }
    return result
    
  end

  
  def get_or_create_child(name)
    child=@children.detect{ |each| each.name == name}
    if child == nil then
      child= Node.new(name)
      add_child(child)
    end
    return child
  end

  def find_node(path)
    child = get_or_create_child(path.first)
    if path.size > 1 then
      return child.find_node(path[1..-1])
    else
      return child
    end
  end


  def parse_head_tail(head, tail)
    add_path(path_to_list(head), tail)
  end

  def add_path(path, tail)
    node= find_node(path)
    node.parse_tail(tail)
  end

  def file_is_allowed?(name)
    return (not /\....$/.match(name) )
  end


  def parse_tail(tail)
    tail.scan(/(.+\.(...))$/) {
      item=$1
      if file_is_allowed?(item) then
        get_or_create_child(item)
      end
    }
  end

  def add_child(node)
    @children.push(node)
    return node
  end

    
  def write_on(stream, indent)
    (1..indent).each{ |i| stream << "  "}
    stream << name << "\n"
    children.sort.each{ |child| child.write_on(stream, indent+1)}
  end
  
  def write_html_on(stream)
   
    stream << "<li>" <<  name << "<br>"
    if children.size > 0
      stream << "<ul>"
      children.sort.each{ |child| child.write_html_on(stream)}
      stream << "</ul>" 
    end
    stream << "</li>"
  end


  def <=> other
      return name <=> other.name
  end

  def to_s
    result=""
    write_on(result, -2)
    return result
  end
  
  def to_html
    result="<html><body>"
    write_html_on(result)
    result << "</body></html>"    
  end

  
end



root = Node::from_lslist(File.read(ARGV[0]))

result = root.to_s

result.gsub!("_"," ")

puts result




