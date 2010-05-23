#!/usr/bin/env ruby

class Counter

  attr_reader :contents

  def initialize(array)
    @contents = Hash.new(0)
    array.each { |e| @contents[e] += 1 }
  end

end

a = %w[red blue red green blue blue]
c = Counter.new(a)
puts c.contents
