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
elsif ENV['TM_CURRENT_WORD'] != nil
  input_value = ENV['TM_CURRENT_WORD'].dup
else
  puts "You have not selected a number to convert into ems."
  exit
end

input_value.gsub!(/\D*/, '')
font_size_converted_to_ems = (input_value.to_f / global_font_size_in_px.to_i)
if font_size_converted_to_ems.denominator == 1 
  print font_size_converted_to_ems.round.to_s + "em"
else
  print font_size_converted_to_ems.round(3).to_s + "em"
end