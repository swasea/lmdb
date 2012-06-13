"converts file of the  'ls -R output' to a data structure.
and pretty prints it"

module LsTree
  
  class Node
    attr_accessor :name
    attr_accessor :children
    attr_accessor :parent
    attr_accessor :indet_per_level


    def initialize(name)
      @name=name
      @children=[]
      @indet_per_level=1
      @parent=nil
    end

    def path
      if parent
        return (parent.path.to_s +  "\/" + name.to_s).sub("\/\/","\/")
      else
        return name
      end
    end

    def Node::from_lslist(buffer)
      node= Node.new("")
      re_lsR = /(.*?):(.*?)\n(\n|$)/m
      if re_lsR.match(buffer) then
        buffer.scan(re_lsR) { |m| 
          node.parse_head_tail($1, $2)
        }
      else # normal ls
        node.parse_head_tail("", buffer)
      end
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
        child.parent= self
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

    def file_is_allowed?(name, allowed_suffixes)
      if /^(.*)\.(...)$/.match(name)
        basname=$1
        suffix=$2
        return allowed_suffixes.match(suffix)
      else #is dir
        return true
      end
    end

    def filter_suffixes(suffixes)
      return nil if not @children 
      @children = @children.select { |each|
        file_is_allowed?(each.name, suffixes) 
      }
      @children.each { |each| each.filter_suffixes(suffixes)} 
    end

    def parse_tail(tail)
      tail.scan(/(.+\.(...))$/) {
        get_or_create_child($1)
      }
    end

    def add_child(node)
      @children.push(node)
      return node
    end

    
    def write_on(stream, indent)
      (1..indent).each{ |i| stream << "  "}
      stream << name << "\n" if name.size > 0
      children.sort.each{ |child| child.write_on(stream, 
                                                 indent+root_indet_per_level)}
    end
    
    def root_indet_per_level
      if parent == nil
        return @indet_per_level
      else
        return parent.root_indet_per_level
      end
    end

    def write_html_on(stream)
      stream << "<li>" <<  name << "<br>" << "\n"
      if children.size > 0
        write_children_html_on(stream)
      end
      stream << "</li>" << "\n"
    end

    def write_children_html_on(stream)
      stream << "<ul>" << "\n"
      children.sort.each{ |child| child.write_html_on(stream)}
      stream << "</ul>" << "\n"
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
      result="<html><body>\n"
      # a quick and dirty hack...
      children[0].write_children_html_on(result)
      result << "\n</body></html>"    
    end
    
    def <=> other
      return name <=> other.name
    end
    
    def hash
      return name.hash
    end
    
    def eql? other
      return ((other.class == self.class) and 
              (children.size == 0) and
              (name == other.name))
    end

    def file_list
      result = children.collect { |node| node.name}
      result = result.select { |each| each }
      children.each {|node| result.concat(node.file_list)}
      return result
    end


    def each(&block)
      block.call(self)
      children.each{ |child| 
        child.each &block
        
      }
    end
    
  end
end





