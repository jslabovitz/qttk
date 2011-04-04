class Array
    
  def sum
    inject(0) { |sum, x| sum + x}
  end
  
  def mean
    sum.to_f / size
  end
  alias :average :mean
  
  # http://www.java2s.com/Code/Ruby/Method/meanandstandarddeviation.htm
  
  def mean_stdev
    m = mean
    variance = inject(0) { |v, x| v + ((x - m) ** 2) }
    [m, Math::sqrt(variance / size)]
  end
  
  # http://en.wikipedia.org/wiki/Mean#Weighted_arithmetic_mean
  
  def weighted_mean(weights)
    raise "Each element of the array must have an accompanying weight.  Array length = #{self.size} versus Weights length = #{weights_array.size}" if weights_array.size != self.size
    w_sum = weights.sum
    w_prod = 0
    each_index { |i| w_prod += self[i] * weights[i].to_f }
    w_prod.to_f / w_sum.to_f
  end

  def randomize(seed=nil)
    old_seed = srand(seed) if seed
    new_array = sort_by { rand }
    srand(old_seed) if seed
    new_array
  end
  
end
