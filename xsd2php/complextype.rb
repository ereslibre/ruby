# -*- coding: utf-8 -*-

##
## Copyright (C) 2010 Rafael Fernández López <ereslibre@ereslibre.es>
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
##

require "argument"

class SimpleContent

  attr_reader :base, :attributes

  def initialize(base, attributes)
    @base = base
    @attributes = attributes
  end

end

class Attribute

  attr_reader :name, :type, :use, :default

  def initialize(name, type, use, default)
    @name = name
    @type = type
    @use = use
    @default = default
  end

end

class ComplexType

  attr_reader :name, :arguments, :choices, :simple_content, :attributes

  def initialize(name, contents)
    @name = name
    for key, value in contents
      if key == "sequence"
        @arguments = Array.new
        sub_contents = value[0]
        for key, value in sub_contents
          case key
            when "element"
              for key, value in value
                @arguments << Argument.new(key, value["type"], value)
              end
            when "sequence"
              sub_contents = value[0]["element"]
              for key, value in sub_contents
                @arguments << Argument.new(key, value["type"], value)
              end
            when "choice"
              @choices = Array.new
              sub_contents = value[0]["element"]
              for key, value in sub_contents
                @choices << Argument.new(key, value["type"], value)
              end
            when "any"
              @arguments << Argument.new("any", nil, nil)
            else
              puts "!!! Unknown data structure when parsing XSD"
          end
        end
      elsif key == "simpleContent"
        base = value[0]["extension"][0]["base"]
        attributes = Array.new
        for attribute in value[0]["extension"][0]["attribute"]
          attributes << Attribute.new(attribute[0], attribute[1]["type"], attribute[1]["use"],
                                      attribute[1]["default"])
        end
        @simple_content = SimpleContent.new(base, attributes)
      elsif key == "choice"
        @choices = Array.new
        sub_contents = value[0]["element"]
        for key, value in sub_contents
          @choices << Argument.new(key, value["type"], value)
        end
      elsif key == "attribute"
        @attributes = Array.new
        for key, value in value
          @attributes << Attribute.new(key, value["type"], value["use"], value["required"])
        end
      elsif key == "mixed"
      elsif key == "anyAttribute"
      end
    end
  end

end
