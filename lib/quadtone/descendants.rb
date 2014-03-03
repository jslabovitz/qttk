# from http://stackoverflow.com/a/2393878

class Class

  def descendants
    ObjectSpace.each_object(::Class).select { |c| c < self }
  end

end