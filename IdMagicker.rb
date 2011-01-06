#!/bin/env ruby

class String
  def starts_with?(characters)
      self.match(/^#{characters}/) ? true : false
  end
end

class Array
    def batch(batch_size)
        for i in 0..(self.size() / batch_size).floor do
            output = self[(i * batch_size),batch_size]

            if output.size > 0
                yield output
            end
        end
    end
end
class LayoutEngine
    def initialize(plot_area, marker_size, marker_margin)
        @plot_area = plot_area
        @marker_size = marker_size
        @marker_margin = marker_margin
        @marker_span = marker_size + marker_margin * 2
    end

    def max_intake()
        return (@plot_area[0] / @marker_span).floor * (@plot_area[1] / @marker_span).floor
    end

    def plot_locations(num_intake)
        col_num = (@plot_area[0] / @marker_span).floor - 1
        row_num = (@plot_area[1] / @marker_span).floor - 1

        plots = Array.new()

        for y in 0..row_num do
            y_loc = y * @marker_span + @marker_margin
            for x in 0..col_num do
                x_loc = x * @marker_span + @marker_margin
                plots << [x_loc, y_loc]

                if plots.size == num_intake
                    return plots
                end
            end
        end

        return plots
    end
end

def path_from_id(id)
    return "BchThin_%04d.png" % id
end

def scale_ppi(real, ppi)
    return ((ppi / 25.4) * real).to_i
end
if ARGV.size < 3
    puts "Args: (output file) (marker size) (marker padding) [id] [id]...."
    exit
end

$o_ppi = 300
$o_size = [209.97, 297.01]
$o_margin = [12.0, 15.0]
$o_actual = [$o_size[0] - $o_margin[0] * 2, $o_size[1] - $o_margin[1] * 2]
$o_actual_pix = $o_actual.collect {|i| scale_ppi(i, 300)}
$o_final_pix = $o_size.collect{|i| scale_ppi(i, 300)}
$m_size = Float(ARGV[1])
$m_padding = Float(ARGV[2])
$output_file = ARGV[0]

images = ARGV[3..-1].collect { |f| path_from_id(f) }
layout = LayoutEngine.new($o_actual, $m_size, $m_padding)

puts "%d markers per page" % layout.max_intake()
puts $o_actual_pix

system("rm %s_*" % $output_file)

i = 0
images.batch(layout.max_intake()){ |farr|
    puts "Processing batch %d" % i
   output_full = "%s_%d.png" % [$output_file, i]
   system("convert -size %dx%d xc:white %s" % [$o_actual_pix[0], $o_actual_pix[1], output_full])
   i = i + 1
    j = 0
    image_pos = layout.plot_locations(farr.size)
    farr.each { |image|
        convert_arg = "-scale %dx%d %s png:-" % [scale_ppi($m_size, $o_ppi), scale_ppi($m_size, $o_ppi), image]
        composite_arg = "-geometry +%d+%d png:- %s %s" % [scale_ppi(image_pos[j][0], $o_ppi), scale_ppi(image_pos[j][1], $o_ppi), output_full, output_full]
        system("convert %s | composite %s" % [convert_arg, composite_arg])
        j = j + 1
    }

    system("mogrify -gravity center -extent %dx%d %s" % [$o_final_pix[0], $o_final_pix[1], output_full])
}

system("convert %s_* %s.pdf" % [$output_file, $output_file])

