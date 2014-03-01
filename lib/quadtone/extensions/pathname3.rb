class Pathname
  
  def with_extname(extname)
    Pathname.new(without_extname.to_s + extname)
  end
  
  def without_extname
    Pathname.new(to_s.sub(/#{Regexp.quote(self.extname)}$/, ''))
  end
  
end