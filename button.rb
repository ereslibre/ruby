#!/usr/bin/env ruby

class Button

  attr_accessor :name

  def initialize(name)
    @name = name
    @on_click = nil
  end

  def button_clicked
    if @on_click != nil
      @on_click.call
    else
      puts "No linked action"
    end
  end

  def on_click(&block)
    @on_click = block
  end

end

def play
  puts "Playing..."
end

def pause
  puts "Pausing..."
end

button = Button.new("Play")
button.button_clicked
button.on_click { play }
button.button_clicked
button.on_click { pause }
button.button_clicked
