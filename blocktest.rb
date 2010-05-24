#!/usr/bin/env ruby

require "pp"

def fibUpTo(max)
	n1, n2 = 1, 1
	while n1 <= max
		yield n1
		n1, n2 = n2, n1 + n2
	end
end

def into(array)
	return lambda { |val| array << val }
end

fibUpTo 50, &into(a = [])
pp a
