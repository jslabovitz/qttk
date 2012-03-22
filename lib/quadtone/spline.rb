# after http://www.akiti.ca/CubicSpline.html

# try http://www.geometrictools.com/LibMathematics/Interpolation/Interpolation.html

class Spline
  
  class Point < Struct.new(:x, :y); end
  
  def initialize(points)

    raise "Must be at least 2 points to make spline" unless points.length >= 2

    @in_points = points
    @num_in_points = points.length
    
    # Check that pairs are entered in order of increasing x-value
    1.upto(@num_in_points - 1).each do |i|
      raise "The data pairs have NOT been entered in order of increasing x-value" if @in_points[i].x <= @in_points[i - 1].x
    end
  
    # Differences between the x-values are now stored in a[. . .], starting with a[1]
    # Divided differences between y-values are stored in b[. . .], starting with b[1]
    # Note that a[0] and b[0] are not filled in this loop they are presently left unassigned

    a = []
    b = []
    @dVec = []        # Array of derivatives at each of the xi points
    
    j = 1
    0.upto(@num_in_points - 2).each do |i|
     a[j] = @in_points[j].x - @in_points[i].x
     b[j] = (@in_points[j].y - @in_points[i].y) / a[j]
     j += 1
    end

    if @num_in_points == 2
      b[0] = a[0] = 1.0
      @dVec[0] = 2.0 * b[1]
    else
      tempx = dummy = a[1]
      b[0] = a[2]
      a[0] = tempx + a[2]
      dummy *= dummy * b[2]
      @dVec[0] = ((tempx + 2.0 * a[0]) * b[1] * a[2] + dummy) / a[0]
    end

    nj = @num_in_points - 1
    1.upto(nj - 1).each do |i|
      tempx = -(a[i + 1] / b[i - 1])
      @dVec[i] = tempx * @dVec[i - 1] + 3.0 * (a[i] * b[i + 1] + a[i + 1] * b[i])
      b[i] = tempx * a[i - 1] + 2.0 * (a[i] + a[i + 1])
    end

    if @num_in_points == 2
      @dVec[1] = b[1]
    else
      if @num_in_points == 3
        @dVec[2] = 2.0 * b[2]
        b[2] = 1.0
        tempx = -(1.0 / b[1])
      else
        tempx = a[@num_in_points - 2] + a[@num_in_points - 1]
        dummy = a[@num_in_points - 1] * a[@num_in_points - 1] * (@in_points[@num_in_points - 2].y - @in_points[@num_in_points - 3].y)
        dummy /= a[@num_in_points - 2]
        @dVec[@num_in_points - 1] = ((a[@num_in_points - 1] + 2.0 * tempx) * b[@num_in_points - 1] * a[@num_in_points - 2] + dummy) / tempx
        tempx = -(tempx / b[@num_in_points - 2])
        b[@num_in_points-1] = a[@num_in_points - 2]
      end

      # Complete forward pass of Gauss Elimination

      b[@num_in_points - 1] = tempx * a[@num_in_points - 2] + b[@num_in_points - 1]
      @dVec[@num_in_points - 1] = (tempx * @dVec[@num_in_points - 2] + @dVec[@num_in_points - 1]) / b[@num_in_points - 1]
    end

    # Carry out back substitution
    (@num_in_points-2).downto(0).each do |i|
      @dVec[i] = (@dVec[i] - a[i] * @dVec[i + 1]) / b[i]
    end

    # End of PCHEZ
  end

  def interpolate(x)
    
    out_points = [x].map { |x| Point.new(x, nil) }
    
    # Begin PCHEV

    # Main loop. Go through and calculate interpolant at each out_points value

    nxt = []
    ir = 1
    jfirst = 0
    while jfirst < out_points.length

      # Locate all points in interval

      k = jfirst
      while k < out_points.length
        break if out_points[k].x >= @in_points[ir].x
        k += 1
      end
      if k < out_points.length && ir == @num_in_points - 1
        k = out_points.length
      end

      nj = k - jfirst

      # Skip evaluation if no points in interval

      if nj > 0

        # Evaluate Cubic at out_points[k].x, j = jfirst (1) to k-1
        # =========================================================
        # Begin CHFDV

        xma = h = @in_points[ir].x - @in_points[ir - 1].x

        n1 = n0 = 0
        xmi = 0.0

        # Compute Cubic Coefficients (expanded about x1)

        delta = (@in_points[ir].y - @in_points[ir - 1].y) / h
        del1 = (@dVec[ir - 1] - delta) / h
        del2 = (@dVec[ir] - delta) / h

        #delta is no longer needed

        c2 = -(del1 + del1 + del2)
        c2t2 = c2 + c2
        c3 = (del1 + del2) / h

        # h, del1, and del2 are no longer needed

        c3t3 = c3 + c3 + c3

        # Evaluation loop
      
        0.upto(nj - 1). each do |j|
          dummy = out_points[jfirst + j].x - @in_points[ir - 1].x
          out_points[jfirst + j].y = @in_points[ir - 1].y + dummy * (@dVec[ir - 1] + dummy * (c2 + dummy * c3))
          n0 += 1 if dummy < xmi
          n1 += 1 if dummy > xma
          # Note the redundancy: if either condition is true, other is false
        end
            
        # End CHFDV

        # ========================================================

        raise "n1: ir != @num_in_points - 1" if n1 > 0 && ir != @num_in_points - 1

        if n0 > 0 && ir != 1
          # out_points is not ordered relative to @in_points, so must adjust evaluation interval
          # First, locate first point to left of @in_points[ir - 1].x
          j = jfirst
          while j < k
      	    break if out_points[j].x < @in_points[ir - 1].x
      	    j += 1
      	  end
          raise "n0: j == k" if j == k
          k = j #Reset k. This will be the first new jfirst

        	# Now find out how far to back up in the xi array
        
          while j < ir
        	  break if out_points[k].x < @in_points[j].x
        	  j += 1
      	  end

        	# The above loop should NEVER run to completion because out_points[k].x < @in_points[ir - 1].x

          # At this point, either out_points[k].x < @in_points[0].x or
        	#                       @in_points[j-1].x <= out_points[k].x < @in_points[j].x
        	# Reset ir, recognizing that it will be incremented before cycling

        	ir = (j - 1) > 0 ? (j - 1) : 0
        end

        jfirst = k

      end

      ir += 1
      break if ir >= @num_in_points

    end

    # End PCHEV
    
    out_points.first
  end
 
end

if $0 == __FILE__
  
  require 'pp'
  
  points = [
    [0.5, 0.25], 
    [1.0, 1.0], 
    [2.0, 4.0], 
    [3.0, 9.0], 
    [4.0, 16.0], 
    [5.0, 25.0],
  ]

  spline = Spline.new(points.map { |p| Spline::Point.new(*p) })

  ;;pp spline

  [1.5, 2.5, 10].each do |x|
    ;;pp({x => spline.interpolate(x)})
  end
  
end