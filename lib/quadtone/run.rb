module Quadtone

  def self.run(*args)
    args = args.flatten.compact.map { |a| a.to_s }
    warn "\t* #{args.join(' ')}"
    system(*args)
    raise "Error: #{$?}" unless $? == 0
  end

end