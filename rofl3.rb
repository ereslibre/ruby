#!/usr/bin/env ruby

class MyClass
end

my_instance = MyClass.new

my_instance.instance_eval do

  def my_method
    "Hello, myMethod on myInstance"
  end

end

puts my_instance.my_method

other_instance = MyClass.new

begin

  other_instance.myMethod

  rescue Exception => msg
  puts "There is no such method in otherInstance ! (#{msg})"

end
