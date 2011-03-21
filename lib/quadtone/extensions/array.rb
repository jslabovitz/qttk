class Array
  
  # sum and mean found on http://snippets.dzone.com/posts/show/2161
  
  def sum
    inject(nil) { |sum, x| sum ? sum + x : x }
  end
  
  def binary_sum
    inject(nil) { |sum, x| sum ? sum | x : x }
  end

  def mean
    sum.to_f / size
  end
  alias :average :mean
  
  # http://en.wikipedia.org/wiki/Mean#Weighted_arithmetic_mean
  
  def weighted_mean(weights_array)
    raise "Each element of the array must have an accompanying weight.  Array length = #{self.size} versus Weights length = #{weights_array.size}" if weights_array.size != self.size
    w_sum = weights_array.sum
    w_prod = 0
    self.each_index {|i| w_prod += self[i] * weights_array[i].to_f}
    w_prod.to_f / w_sum.to_f
  end
  
  def randomize(seed=nil)
    old_seed = srand(seed) if seed
    new_array = sort_by { rand }
    srand(old_seed) if seed
    new_array
  end
  
end
