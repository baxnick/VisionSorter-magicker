#!/bin/env ruby

def path_from_id(id)
    return "BchThin_%04d.png" % id
end

def scale_ppi(real, ppi)
    return ((ppi / 25.4) * real).to_i
end

if ARGV.size < 9
    puts "Args: (output file) (marker size) (marker padding) (front) (left) (back) (right) (top) [bottom]"
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
$m_span = $m_size + $m_padding * 2
$output_file = ARGV[0]

$template_image = "cube_template.png"
$cube_geom = [[815, 1575],[80,840],[815,100],[1550,840],[815,840],[815,2310]]
images = ARGV[3..-1].collect { |f| path_from_id(f) }


output_final = "%s.png" % $output_file
system("convert %s %s" % [$template_image, output_final])

for i in 1..6
    scale_cmd = "convert -scale %dx%d %s png:-" % [scale_ppi($m_size, $o_ppi), scale_ppi($m_size, $o_ppi), images[i - 1]]
    extent_cmd = "convert -gravity center -extent %dx%d png:- png:-" % [scale_ppi($m_span, $o_ppi), scale_ppi($m_span, $o_ppi)]
    marker_cmd = "%s | %s" % [scale_cmd, extent_cmd]

    if i == 2
        marker_cmd = marker_cmd + " | convert -rotate 90 png:- png:-"
    end

    if i == 3
        marker_cmd = marker_cmd + " | convert -rotate 180 png:- png:-"
    end

    if i == 4
        marker_cmd = marker_cmd + " | convert -rotate 270 png:- png:-"
    end

    composite_cmd = "composite -geometry +%d+%d png:- %s %s" % [$cube_geom[i-1][0], $cube_geom[i-1][1], output_final, output_final]

    system("%s | %s" % [marker_cmd, composite_cmd])
end

system("mogrify -gravity center -extent %dx%d %s" % [$o_final_pix[0], $o_final_pix[1], output_final])
system("convert %s %s.pdf" % [output_final, $output_file])
