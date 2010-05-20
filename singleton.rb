#!/usr/bin/env ruby

class Singleton

  private_class_method :new

  @@instance = nil

  def Singleton.self
    @@instance = new unless @@instance
    @@instance
  end

end

5.times { puts Singleton.self.to_s }
