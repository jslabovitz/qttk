class Pathname
  
  def with_extname(extname)
    Pathname.new(to_s.sub(/#{Regexp.quote(self.extname)}$/, extname))
  end
  
end