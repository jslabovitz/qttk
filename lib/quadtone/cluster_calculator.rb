# after:
#   http://colinfdrake.com/2011/05/28/clustering-in-ruby.html
#   http://m635j520.blogspot.com/2013/02/implementing-k-means-clustering-in-ruby.html

class ClusterCalculator

  class Cluster

    attr_accessor :center
    attr_accessor :samples
    attr_accessor :moved

    def initialize(center)
      @center = center
      @samples = []
      @moved = true
    end

    def add_sample(sample)
      @samples << sample
    end

    def clear_samples
      @samples = []
    end

    def distance_to(sample)
      @center.delta_e(sample.output)
    end

    def update_center(delta=0.001)
      @moved = false
      average, error = Color::Lab.average(@samples.map(&:output))
      unless average.delta_e(@center) < delta
        @center = average
        @moved = true
      end
    end

    def size
      @samples.length
    end

  end

  attr_accessor :samples
  attr_accessor :max_clusters
  attr_accessor :delta
  attr_accessor :clusters

  def initialize(params={})
    @delta = 0.001
    params.each { |k, v| send("#{k}=", v) }
    raise "Must specify samples" unless @samples
    raise "Must specify max_clusters" unless @max_clusters
    @max_clusters = @samples.length if @max_clusters > @samples.length
  end

  def cluster!
    @clusters = @max_clusters.times.map { Cluster.new(@samples.sample.output) }
    while @clusters.any?(&:moved)
      @clusters.each(&:clear_samples)
      @samples.each do |sample|
        shortest = Float::INFINITY
        cluster_found = nil
        @clusters.each do |cluster|
          distance = cluster.distance_to(sample)
          if distance < shortest
            cluster_found = cluster
            shortest = distance
          end
        end
        cluster_found.add_sample(sample) if cluster_found
      end
      @clusters.delete_if { |c| c.size == 0 }
      @clusters.each { |c| c.update_center(@delta) }
    end

  end

end