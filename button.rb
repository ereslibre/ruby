#!/usr/bin/env ruby

class Button

  attr_accessor :name

  def initialize(name)
    @name = name
    @onClick = nil
  end

  def buttonClicked
    if @onClick != nil
      @onClick.call
    else
      puts "No linked action"
    end
  end

  def onClick(&block)
    @onClick = block
  end

end

def play
  puts "Playing..."
end

def pause
  puts "Pausing..."
end

button = Button.new("Play")
button.buttonClicked
button.onClick { play }
button.buttonClicked
button.onClick { pause }
button.buttonClicked
