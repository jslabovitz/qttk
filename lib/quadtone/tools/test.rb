module Quadtone

  module Tools

    class Test < Tool

      def run
        # - test linearization
        #
        #   - print grayscale target image with QTR curve, then measure target
        #   - analyze measured target
        #     - build grayscale curve from samples
        #     - test for linear response
        #     - show dMin/dMax, Lab curve
        #
        #   - store each test with timestamp
        #
        #   - chart scale over time (with multiple tests)
        #     - graph differences between values
        #     - graph average dE
        #       - see: http://cias.rit.edu/~gravure/tt/pdf/pc/TT5_Fred01.pdf (p. 34)

        # test_grayscale_name = 'test-grayscale'
        #
        # test_grayscale_measured_path = Pathname.new(test_grayscale_name + '.measured.txt')
        #
        # wait_for_file(test_grayscale_measured_path, "print & measure target #{grayscale_reference_path} -- save data to #{test_grayscale_measured_path}")
        #
        # test_grayscale_measured_target = Target.from_ti3_file(test_grayscale_measured_path)
        # test_grayscale_measured_curveset = CurveSet.from_samples(test_grayscale_measured_target.samples)
        # test_grayscale_measured_curveset.write_svg_file(test_grayscale_measured_path.with_extname('.svg'))

        #FIXME: See above

        image_file = Pathname.new('test.tif')
        image_list = Magick::ImageList.new
        begin
          bounds = Magick::Rectangle.new(350, 50, 0, 0)
          image1 = Magick::Image.new(bounds.width, bounds.height/2, Magick::GradientFill.new(0, 0, 0, bounds.height/2, 'white', 'black'))
          image2 = image1.posterize(21)
          ilist = Magick::ImageList.new
          ilist << image1
          ilist << image2
          image_list << ilist.append(true)
        end
        begin
          bounds = Magick::Rectangle.new(350, 350, 0, 0)
          image1 = Magick::Image.new(bounds.width, bounds.height/2, Magick::GradientFill.new(bounds.width/2, bounds.height/2, bounds.width/2, bounds.height/2, 'black', 'white'))
          image2 = image1.posterize(21).flip
          ilist = Magick::ImageList.new
          ilist << image1
          ilist << image2
          image_list << ilist.append(true)
        end
        begin
          bounds = Magick::Rectangle.new(350, 350, 0, 0)
          ilist = Magick::ImageList.new(Pathname.new($0) + '../../etc/images/4843128953_83c1770907_o.jpg')
          image_list << ilist.first.resize_to_fill(350, 350)
        end
        final_image = image_list.append(true)
        ;;warn "writing #{image_file}"
        final_image.write(image_file) { self.compression = Magick::ZipCompression }

      end

    end

  end

end