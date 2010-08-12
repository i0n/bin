#!/usr/bin/env ruby -w
# encoding: utf-8

# NOTE! The denominator method does not like Ruby 1.8.x at all. May I suggest getting yourself upgraded to 1.9.2+ It's the future!

require 'find'

Find.find(ENV['TM_PROJECT_DIRECTORY']) do |x|
  case
  when File.file?(x) && x =~ /\/global\.css$/ then
    @global_css_file_path = x
  when File.file?(x) && x =~ /\/screen\.css$/ then
    @screen_css_file_path = x
  end
end

file = IO.read(@global_css_file_path)
html_body_rules = file.match(/(html > body \{)([^\}]*)(\}{1})/m)[0]
global_font_size_in_px = html_body_rules.match(/font-size:[\s+](\d+)px/)[1]

if ENV['TM_SELECTED_TEXT'] != nil
  input_value = ENV['TM_SELECTED_TEXT'].dup
# Having to disable the use of Textmate's TM_CURRENT_WORD variable in em to px conversion until I can figure out how to get it to treat the values either side of a decimal point as the same number or 'current word'
# elsif ENV['TM_CURRENT_WORD'] != nil
#   input_value = ENV['TM_CURRENT_WORD'].dup
  input_value.gsub!(/[^0-9\.]/, '')
  font_size_converted_to_px = (input_value.to_f * global_font_size_in_px.to_i)
  print font_size_converted_to_px.round.to_s + "px"
else
  print ENV['TM_CURRENT_WORD']
end

