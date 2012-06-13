
require 'lstree/lstree'


class Medium
  include Enumerable
  attr_accessor :name
  attr_accessor :prefix
  attr_accessor :root  
  attr_accessor :text  

  def Medium::from_file(filename)
    medium=self.new
    medium.name=File.basename(filename,".cdrom")
    medium.text=File.read(filename)
    medium.load
    medium.prefix= "."
    return medium
  end

  def id
    return name
  end

  def load
    @root= LsTree::Node::from_lslist(@text)
  end

  def clear
    @root=nil
  end

  def to_s
    return "medium: %s prefix: %s" % [name, prefix]
  end

  def each &block
    root.each &block if root
  end


  # html generation

  def html_div_files(files)
    
    result= ""
    result << '  <div class="files">'   
    result << '    <div class="medium_id">' << id << '</div>' << "\n"
    files.sort {|a,b| a.file <=> b.file}.each { |each| 
      
      filepath=prefix+each.file
      if File.exist? filepath
        result << '<a href="' <<  
            CGI::escape(filepath) << '">' << 
          each.name << '</a>' 
      else
        result << each.name
        end
      result << '<br> '
    }
    result << "</div>"
    return result
  end

  def dynamic?
    return false
  end
end


class DynamicMedium < Medium

  def load

  end

  def visit_each(file, block)
    if File.directory?(file) 
      Dir.glob(file+"/*").each {|eachFile|
        visit_each(eachFile, block)
      }
    else
      if /\.((avi)|(mpg)|(mpeg)|(ogm))$/.match(file)
        block.call(file)
      end
    end
  end

  def each &block
    visit_each(prefix, block)
  end

  def Medium::from_dir(directory)
    medium=self.new
    medium.name=directory
    medium.load
    medium.prefix= directory
    return medium
  end
  
  def dynamic?
    return true
  end



  def html_div_files(files)
    
    result= ""
    result << '  <div class="files">'   
    files.sort {|a,b| a.file <=> b.file}.each { |each| 
      filepath=each.file
      result << '<a href="' <<  
      filepath << '">' << 
      each.name << '</a>' << '<br> '
    }
    result << "</div>"
    return result
  end


end
