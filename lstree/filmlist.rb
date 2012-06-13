

require 'lstree/lstree'

include LsTree

class Node

  def remove_suffixes()
    @name.sub!(/\.(...)$/,"")
    
    children.each { |child| child.remove_suffixes}
  end

  def remove_multipartstring()
    name.sub!(/_\[?\d+_?((of)|(von))_?\d+\]?/,"")
    children.each { |child| child.remove_multipartstring}
  end

  def remove_depricated_multipartstring()
    name.sub!(/((cd)|(CD)|(part))_?\d?/,"")
    children.each { |child| 
      child.remove_depricated_multipartstring}
  end

  def remove_cdrom_root()
    if name == "/cdrom"
      @name= ""
    end
    children.each { |child| child.remove_cdrom_root}
  end

  def remove_dir_names()
    if not /^(.*)\.(...)$/.match(name)
      @name= ""
    end
    children.each { |child| child.remove_dir_names}
  end

  def remove_braces()
    name.sub!(/(_\(.*\))|(\(.*\))/,"")
    children.each { |child| child.remove_braces}
  end

  def remove_tags()
    name.sub!(/(_\[.*\])|(\[.*\])/,"")
    children.each { |child| child.remove_tags}
  end


  def uniq_children()
    children.uniq!
    children.each { |child| child.uniq_children}
  end
  
  def merge_multipart_filenames()
    remove_multipartstring
    remove_depricated_multipartstring()
    uniq_children
    uniq_hierarchy
  end

  def uniq_hierarchy
    if (children.size == 1) and (children[0].name == name)
      @children=children[0].children
    end
    children.each { |child| child.uniq_hierarchy}
  end

  def Node::cdrom2filmlist(filename)
  
    @root = Node::from_lslist(File.read(filename))
    @root.filter_suffixes(/(avi)|(mpg)|(mpeg)|(ogm)/)
    
    @root.remove_dir_names 
    @root.remove_suffixes()
    @root.remove_cdrom_root
    @root.remove_braces()
    @root.remove_tags()
    @root.merge_multipart_filenames()
    @root.indet_per_level=0
    
    result = @root.to_s
    
    result.gsub!("_"," ")
    
    puts result
  end
end

