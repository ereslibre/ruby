#!/usr/bin/env ruby

module TestModule

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      include InstanceMethods
    end
  end

  module ClassMethods
    def class_test
      puts 'class test'
    end
  end

  module InstanceMethods
    def test
      puts 'test'
    end
  end

end

class Test
  include TestModule
end

Test.class_test
test = Test.new
test.test
