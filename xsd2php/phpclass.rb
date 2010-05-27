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

# Reopen Argument class, and add information that only targets PHP classes. This way we easily allow
# to create backends for other languages.
class Argument

  def to_s
    if @type
      "$#{@name} /* #{@type} */"
    else
      "$#{@name}"
    end
  end

end

class Attribute

  def to_s
    return "$#{@name}" if !@default
    "$#{@name} = \"#{@default}\""
  end

end

class PHPClass

  attr_reader :xsd_class_name, :namespace, :referer, :simple_types, :complex_types, :elements

  @@simple_types = Hash.new
  @@complex_types = Hash.new

  def type(type_name)
    return @@complex_types[type_name] if @@complex_types.has_key? type_name
    @@simple_types[type_name] if @@simple_types.has_key? type_name
  end

  def initialize(destination, contents, file_name)
    @destination = destination
    extension = file_name.slice(/\.(\w+)$/)
    @xsd_class_name = File.basename(file_name, extension).slice(/(\w*)/)
    if contents["targetNamespace"]
        @namespace = contents["targetNamespace"].slice(/^((.*):)*(\w*)/, 3)
    else
        @namespace = nil
    end
    @referer = contents["xmlns:#{@namespace}"]
    @simple_types = Hash.new
    @complex_types = Hash.new
    @elements = Array.new
    for key, value in contents
      if key == "simpleType"
        for curr_key, curr_value in value
          simple_type = SimpleType.new("#{@namespace}:#{curr_key}", curr_value["restriction"])
          @simple_types[curr_key] = simple_type
          @@simple_types["#{@namespace}:#{curr_key}"] = simple_type
        end
      elsif key == "complexType"
        for curr_key, curr_value in value
          complex_type = ComplexType.new("#{@namespace}:#{curr_key}", curr_value)
          @complex_types[curr_key] = complex_type
          @@complex_types["#{@namespace}:#{curr_key}"] = complex_type
        end
      elsif key == "element"
        for curr_key, curr_value in value
          type = curr_value["type"]
          @elements << Element.new(curr_key, type ? type : curr_value, @namespace)
        end
      end
    end
  end

  def write_class(php_classes)
    return if @elements.empty?
    file = File.new("#{@destination}/#{@xsd_class_name}.php", "w")
    wtf(file) { "<?php\n\n" }
    write_header(file, @namespace)
    wtf(file) { "class #{@xsd_class_name}\n{\n" }
    write_elements(file, php_classes)
    wtf(file) { "\n}\n\n?>\n" }
    file.close
  end

  private

  def write_elements(file, php_classes)
    for element in @elements
      input = "$#{element.type.slice(/(\w*):(\w*)/, 2)}"
      wtf(file) { "\n\tpublic function do_#{element.name}(#{input}) {\n" }
      wtf(file) { "\t\t$res = \"<#{@namespace}:#{element.name}>\";\n" }
      wtf(file) { "\t\t$res += #{input}\n" }
      wtf(file) { "\t\t$res += \"</#{@namespace}:#{element.name}>\";\n" }
      wtf(file) { "\t\treturn $res;\n" }
      wtf(file) { "\t}\n" }
    end
    for complex_type_key, complex_type in @complex_types
      if complex_type.arguments
        write_complex_type_with_arguments file, complex_type_key, complex_type
      elsif complex_type.choices
        write_complex_type_with_choices file, complex_type_key, complex_type
      elsif complex_type.simple_content
        write_complex_type_with_simple_content file, complex_type_key, complex_type
      else
        puts "!!! Unknown complex type information (#{complex_type_key})"
      end
    end
  end

  def write_complex_type_with_arguments(file, complex_type_key, complex_type)
    wtf(file) { "\n\tpublic function create_#{complex_type_key}(#{complex_type.arguments.join(", ")}) {\n" }
    wtf(file) { "\t\t$res = \"\";\n" }
    for argument in complex_type.arguments
      wtf(file) { "\t\t$res += \"<#{@namespace}:#{argument.name}>$#{argument.name}</#{@namespace}:#{argument.name}>\";\n" }
    end
    wtf(file) { "\t\treturn $res;\n" }
    wtf(file) { "\t}\n" }
  end

  def write_complex_type_with_choices(file, complex_type_key, complex_type)
    wtf(file) { "\n" }
    for choice in complex_type.choices
      wtf(file) { "\tconst #{choice.name.upcase} = \"#{choice.name}\";\n" }
    end
    wtf(file) { "\tpublic function create_#{complex_type_key}($choice) {\n" }
    wtf(file) { "\t}\n" }
  end

  def write_complex_type_with_simple_content(file, complex_type_key, complex_type)
    wtf(file) { "\n\tpublic function create_#{complex_type_key}(#{complex_type.simple_content.attributes.join(", ")}) {\n" }
    wtf(file) { "\t}\n" }
  end

end
