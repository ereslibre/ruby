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

  @@global_simple_types = Hash.new
  @@global_complex_types = Hash.new

  def type(type_name)
    return @@global_complex_types[type_name] if @@global_complex_types.has_key?(type_name)
    @@global_simple_types[type_name] if @@global_simple_types.has_key?(type_name)
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
          @@global_simple_types["#{@xsd_class_name}:#{curr_key}"] = simple_type
        end
      elsif key == "complexType"
        for curr_key, curr_value in value
          complex_type = ComplexType.new("#{@xsd_class_name}:#{curr_key}", curr_value)
          @complex_types[curr_key] = complex_type
          @@global_complex_types["#{@xsd_class_name}:#{curr_key}"] = complex_type
        end
      elsif key == "element"
        for curr_key, curr_value in value
          @elements << Element.new(curr_key, curr_value["type"], @xsd_class_name)
        end
      end
    end
  end

  def write_class(php_classes)
    return if @elements.empty?
    file = File.new("#{@destination}/#{@class_name.downcase}.php", "w")
    write_to_file(file) { "<?php\n\n" }
    write_header(file)
    write_to_file(file) { "class #{@class_name}\n{\n\tprivate $query = \"\";\n\n" }
    write_elements(file, php_classes)
    write_xml_generator(file)
    write_to_file(file) { "}\n\n?>\n" }
    file.close
  end

  private

  def write_elements(file, php_classes)
    for element in @elements
      type = self.type(element.type)
      write_to_file(file) { "\tpublic function do#{element.name.capitalize}(#{type.attributes.join(", ") if type}) {\n" }
      write_to_file(file) { "\t\t$query += \"<#{element.name}>\";\n" }
      write_to_file(file) { "\t\t$query += \"<#{element.xsd_class_name}:#{element.name}>\";\n" }
      write_to_file(file) { "\t\t$query += \"</#{element.xsd_class_name}:#{element.name}>\";\n" }
      write_to_file(file) { "\t\t$query += \"</#{element.name}>\";\n" }
      write_to_file(file) { "\t}\n\n" }
    end
  end

  def write_xml_generator(file)
    write_to_file(file) { "\tpublic function generateXML() {\n" }
    write_to_file(file) { "\t\t$res = \"<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?>\";\n" }
    write_to_file(file) { "\t\t$res += \"<epp xmlns=\\\"urn:ietf:params:xml:ns:epp-1.0\\\" " \
      "xmlns:domain=\\\"urn:ietf:params:xml:ns:domain-1.0\\\" " \
      "xmlns:es_creds=\\\"urn:red.es:xml:ns:es_creds-1.0\\\">\";\n" }
    write_to_file(file) { "\t\t$res += \"<command>\";\n" }
    write_to_file(file) { "\t\t$res += $query;\n" }
    write_to_file(file) { "\t\t$res += \"</command>\";\n" }
    write_to_file(file) { "\t\treturn $res;\n" }
    write_to_file(file) { "\t}\n" }
  end

end
