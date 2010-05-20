#!/usr/bin/env ruby

class Test

  def initialize(name = "foo")
    @name = name
  end

  def sayHello
    if @name.respond_to?("capitalize")
      puts "Hello #{@name.capitalize}"
    else
      puts "Hello #{@name}"
    end
  end

  def sayBye
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

  def sayHelloAndBye
    if @name.respond_to?("capitalize")
      puts "Hello and Bye, #{@name.capitalize}"
    else
      puts "Helo, and Bye, #{@name}"
    end
  end

end

t = Test.new
t.sayHello
t.name = "bar"
t.sayBye
t.name = "rofl"
t.sayHelloAndBye
