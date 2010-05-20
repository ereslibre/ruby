#!/usr/bin/env ruby

class MyClass

  def initialize
  end

end

myInstance = MyClass.new

myInstance.instance_eval do

  def myMethod
    "Hello, myMethod on myInstance"
  end

end

puts myInstance.myMethod

otherInstance = MyClass.new

begin

  otherInstance.myMethod

  rescue Exception => msg
  puts "There is no such method in otherInstance ! (#{msg})"

end
