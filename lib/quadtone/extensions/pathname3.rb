class Pathname
  
  def with_extname(extname)
    Pathname.new(to_s.sub(/\.[^.]+$/, extname))
  end
  
end