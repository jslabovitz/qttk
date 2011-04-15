class Array
    
  def sum
    inject(&:+)
  end
  
  def mean
    sum.to_f / size
  end
  alias :average :mean
  
  # http://www.java2s.com/Code/Ruby/Method/meanandstandarddeviation.htm
  
  def mean_stdev
    m = mean
    variance = inject(0) { |v, x| v + ((x - m) ** 2) } / size
    [m, Math::sqrt(variance)]
  end
  
  # http://en.wikipedia.org/wiki/Mean#Weighted_arithmetic_mean
  def weighted_mean(weights)
    raise "Each element of the array must have an accompanying weight.  Array length = #{self.size} versus Weights length = #{weights_array.size}" if weights_array.size != self.size
    w_sum = weights.sum
    w_prod = 0
    each_index { |i| w_prod += self[i] * weights[i].to_f }
    w_prod.to_f / w_sum.to_f
  end

  def median
  	if length % 2 == 0
  		[self[(length / 2) - 1], self[length / 2]].mean
		else
    	self[length / 2]
  	end
  end
  
  # http://en.wikipedia.org/wiki/Median_absolute_deviation
  def mad
    m = median
  	map { |n| (n - m).abs }.median
  end
  
  def randomize(seed=nil)
    old_seed = srand(seed) if seed
    new_array = sort_by { rand }
    srand(old_seed) if seed
    new_array
  end
  
end
