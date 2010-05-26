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

require "pp"
require "utils"
require "element"
require "simpletype"
require "complextype"
require "restriction"

class PHPClass

  attr_reader :xsd_class_name, :class_name, :simple_types, :complex_types, :elements

  @@simple_types = Hash.new
  @@complex_types = Hash.new

  def type(type_name)
    return @@complex_types[type_name] if @@complex_types.has_key? type_name
    @@simple_types[type_name] if @@simple_types.has_key? type_name
  end

  def initialize(destination, contents)
    @destination = destination
    @xsd_class_name = contents["targetNamespace"].slice(/^((.*):)*(\w*)/, 3)
    @class_name = @xsd_class_name.downcase.capitalize
    @simple_types = Hash.new
    @complex_types = Hash.new
    @elements = Array.new
    for key, value in contents
      if key == "simpleType"
        for curr_key, curr_value in value
          simple_type = SimpleType.new("#{@xsd_class_name}:#{curr_key}", curr_value["restriction"])
          @simple_types[curr_key] = simple_type
          @@simple_types["#{@xsd_class_name}:#{curr_key}"] = simple_type
        end
      elsif key == "complexType"
        for curr_key, curr_value in value
          complex_type = ComplexType.new("#{@xsd_class_name}:#{curr_key}", curr_value)
          @complex_types[curr_key] = complex_type
          @@complex_types["#{@xsd_class_name}:#{curr_key}"] = complex_type
        end
      elsif key == "element"
        for curr_key, curr_value in value
          type = curr_value["type"]
          @elements << Element.new(curr_key, type ? type : curr_value, @xsd_class_name)
        end
      end
    end
  end

  def write_class(php_classes)
    return if @elements.empty?
    file = File.new("#{@destination}/#{@class_name.downcase}.php", "w")
    wtf(file) { "<?php\n\n" }
    write_header(file)
    wtf(file) { "class #{@class_name}\n{" }
    write_elements(file, php_classes)
    write_xml_generator(file)
    wtf(file) { "}\n\n?>\n" }
    file.close
  end

  private

  def write_elements(file, php_classes)
    for element in @elements
      type = self.type(element.type)
      arguments = Array.new
      if type.instance_variables.include? :@arguments
        arguments = type.arguments
        arguments.sort! { | x, y |
          if x.minOccurs == y.minOccurs
            0
          else
            if x.minOccurs == "0"
              1
            else
              -1
            end
          end
        }
      elsif type.instance_variables.include? :@choices
        for choice in type.choices
          wtf(file) { "\n\tconst #{choice.name.upcase} = \"#{choice.name}\";" }
        end
        arguments << Argument.new("choice", nil, nil)
      else
      end
      wtf(file) { "\n\tpublic function do_#{element.name}(#{arguments.join(", ") + ", " if !arguments.empty?}$_inject = \"\", $_namespace = true) {\n" }
      wtf(file) { "\t\t$__namespace = $_namespace ? \"#{@xsd_class_name}:\" : \"\";\n" }
      wtf(file) { "\t\t$res = \"<${__namespace}#{element.name}>\";\n" }

      for argument in arguments
        wtf(file) { "\t\t$res += \"<${__namespace}#{argument.name}>$#{argument.name}</${__namespace}#{argument.name}>\";\n" } if argument.type
      end

      wtf(file) { "\t\t$res += $_inject;\n" }
      wtf(file) { "\t\t$res += \"</${__namespace}#{element.name}>\";\n" }
      wtf(file) { "\t\treturn $res;\n" }
      wtf(file) { "\t}\n" }
    end
  end

  def write_xml_generator(file)
  end

end
