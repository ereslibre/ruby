#!/usr/bin/env ruby

class A

	attr_accessor :a

	def initialize(a)
		@a = a
	end

end

class B < A

	attr_accessor :b

	def initialize(a, b)
		super(a)
		@b = b
	end

end

B.instance_eval {

	def c
		42
	end

}

B.class_eval {

	def d
		84
	end

}

b = B.new(1, 2)
puts b.a
puts b.b
puts B.c # defined with instance_eval (B is a instance of A)
puts b.d # defined with class_eval