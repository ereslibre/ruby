#!/usr/bin/env ruby

class Test

  def initialize(name = "foo")
    @name = name
  end

  def say_hello
    if @name.respond_to?("capitalize")
      puts "Hello #{@name.capitalize}"
    else
      puts "Hello #{@name}"
    end
  end

  def say_bye
    if @name.respond_to?("capitalize")
      puts "Bye #{@name.capitalize}"
    else
      puts "Bye #{@name}"
    end
  end

end

class Test

  attr_accessor :name

end

class Test

  def say_hello_and_bye
    if @name.respond_to?("capitalize")
      puts "Hello and Bye, #{@name.capitalize}"
    else
      puts "Helo, and Bye, #{@name}"
    end
  end

end

t = Test.new
t.say_hello
t.name = "bar"
t.say_bye
t.name = "rofl"
t.say_hello_and_bye
