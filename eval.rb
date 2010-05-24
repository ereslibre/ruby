#!/usr/bin/env ruby

def make_setter(*names)
  for name in names
    eval <<-SETTER
    def #{name}=(arg)
      @#{name} = arg
    end
    public :#{name}=
    SETTER
  end
end

def make_getter(*names)
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

  make_setter :example, :example2
  make_getter :example, :example2

end

t = Test.new
t.example = "Dynamic attribute 1"
t.example2 = "Dynamic attribute 2"
puts t.example
puts t.example2
