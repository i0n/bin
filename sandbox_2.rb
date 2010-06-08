class Red
  def gets(*args)
    @input.gets(*args)
  end
  def puts(*args)
    @output.puts(*args)
  end
  def initialize
    @input = $stdin
    @output = $stdout
  end
  private
  def first_method
    input = gets.chomp
    if input == "test"
      second_method(input)
    end
  end
  def second_method(value)
    puts value
    second_method(value)
  end
end

require 'test/unit'
# require 'stringio'
# require 'rubygems'
require 'mocha'

class Test::Unit::TestCase

end


# MiniTest::Unit.autorun

class RedTest < Test::Unit::TestCase
  def setup
    @project = Red.new
    @project.instance_variable_set(:@input, StringIO.new("test\n"))
    @project.stubs(:second_method)
  end
  
  def test_pass_input_value_to_second_method
    @project.expects(:second_method).with("test").once
    @project.instance_eval {first_method}
  end
end

# $ ruby red_test.rb 
# Loaded suite red_test
# Started
# .
# Finished in 0.000656 seconds.
#
# 1 tests, 1 assertions, 0 failures, 0 errors, 0 skips

# $ ruby -v
# ruby 1.9.2dev (2009-07-18 trunk 24186) [i386-darwin10.3.0] 

# $ gem list mocha
# 
# *** LOCAL GEMS ***
#
# mocha (0.9.8)