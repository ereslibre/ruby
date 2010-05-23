#!/usr/bin/env ruby

def makeSetter(*names)
  for name in names
    eval <<-SETTER
    def #{name}=(arg)
      @#{name} = arg
    end
    public :#{name}=
    SETTER
  end
end

def makeGetter(*names)
  for name in names
    eval <<-GETTER
    def #{name}
      @#{name}
    end
    public :#{name}
    GETTER
  end
end

class Test

  makeSetter :example, :example2
  makeGetter :example, :example2

end

t = Test.new
t.example = "Dynamic attribute 1"
t.example2 = "Dynamic attribute 2"
puts t.example
puts t.example2
