#!/usr/bin/env ruby

class Test
  def _virtualMethod(*args)
    puts "I'm dynamic and was given params: #{args * ", "}"
  end

  def method_missing(method, *args)
    puts "Calling to #{method}"
    _virtualMethod(args)
  end
end

t = Test.new
t.thisMethodDoesNotExist "param1", "param2", 3, 4, "param5"
