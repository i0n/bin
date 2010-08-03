#!/usr/bin/env ruby -w
# encoding: utf-8

require 'find'

Find.find(ENV['TM_PROJECT_DIRECTORY']) do |x|
  case
  when File.file?(x) && x =~ /\/global\.css/ then
    puts "Found #{x}"
    @global_css_file_path = x
  when File.file?(x) && x =~ /\/screen\.css/ then
    puts "Found #{x}"
    @screen_css_file_path = x
  end
end
file = IO.read(@global_css_file_path)
html_body_rules = file.match(/(html > body \{)([^\}]*)(\}{1})/m)[0]
global_font_size_in_px = html_body_rules.match(/font-size:[\s+](\d+)px/)[1]

# input_value = ENV['TM_SELECTED_TEXT'].dup
input_value = "24px"

input_value.gsub!(/\D*/, '')
font_size_converted_to_ems = (input_value.to_f / global_font_size_in_px.to_i)
if font_size_converted_to_ems.denominator == 1 
  puts font_size_converted_to_ems.round.to_s + "em"
else
  puts font_size_converted_to_ems.round(3).to_s + "em"
end 

