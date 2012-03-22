# from http://stackoverflow.com/a/2393878

class Class
  
  def descendants
    ObjectSpace.each_object(::Class).select {|klass| klass < self }
  end
  
end