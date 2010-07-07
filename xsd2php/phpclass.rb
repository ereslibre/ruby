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
    return "$#{@name} /* #{@type} */" if !@default
    "$#{@name} = \"#{@default}\" /* #{@type} */"
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
    return if @elements.empty? && @complex_types.empty?
    file = File.new("#{@destination}/#{@xsd_class_name}.php", "w")
    wtf(file) { "<?php\n\n" }
    write_header(file, @namespace)
    wtf(file) { "class #{@xsd_class_name}\n{\n" }
    wtf(file) { "\n\tprivate $_dependencies = array();" }
    wtf(file) { "\n\tprivate $_query = \"\";\n" }
    write_xml_generator(file)
    write_elements(file, php_classes)
    wtf(file) { "\n}\n\n?>\n" }
    file.close
  end

  private

  def write_elements(file, php_classes)
    for element in @elements
      wtf(file) { "\n\tpublic static function do_#{element.name}($#{element.name} /* #{element.type} */, $_namespace = true) {\n" }
      wtf(file) { "\t\t$__namespace = $_namespace ? \"#{@namespace}:\" : \"\";\n" }
      wtf(file) { "\t\t$_res = new #{@xsd_class_name}();\n" }
      wtf(file) { "\t\t$_res->_query = \"<${__namespace}#{element.name}>\";\n" }
      wtf(file) { "\t\tif (is_string($#{element.name})) {\n" }
      wtf(file) { "\t\t\t$_res->_query .= $#{element.name};\n" }
      wtf(file) { "\t\t} else if ($#{element.name}) {\n" }
      wtf(file) { "\t\t\t$_res->_query .= $#{element.name}->query();\n" }
      wtf(file) { "\t\t\t$_res->_dependencies = $#{element.name}->dependencies();\n" }
      wtf(file) { "\t\t\tif (get_class($_res) != get_class($#{element.name})) {\n" }
      wtf(file) { "\t\t\t\t$_res->_dependencies[] = \"xmlns:\" . $#{element.name}->xml_namespace() . \"=\\\"\" . $#{element.name}->xml_referer() . \"\\\"\";\n" }
      wtf(file) { "\t\t\t}\n" }
      wtf(file) { "\t\t}\n" }
      wtf(file) { "\t\t$_res->_query .= \"</${__namespace}#{element.name}>\";\n" }
      wtf(file) { "\t\treturn $_res;\n" }
      wtf(file) { "\t}\n" }
    end
    for complex_type_key, complex_type in @complex_types
      correct = true
      if complex_type.arguments
        write_complex_type_with_arguments file, complex_type_key, complex_type
      elsif complex_type.choices
        write_complex_type_with_choices file, complex_type_key, complex_type
      elsif complex_type.simple_content
        write_complex_type_with_simple_content file, complex_type_key, complex_type
      elsif complex_type.attributes
        write_complex_type_with_attributes file, complex_type_key, complex_type
      else
        correct = false
        puts "!!! Unknown complex type information (#{complex_type_key})"
      end
      if correct
        wtf(file) { "\t}\n" }
      end
    end
  end

  def write_complex_type_with_arguments(file, complex_type_key, complex_type)
    if complex_type.arguments.empty? && complex_type.choices.empty?
      wtf(file) { "\n\tpublic static function create_#{complex_type_key}($_namespace = true) {\n" }
    else

      for choice in complex_type.choices
        wtf(file) { "\n\tconst #{complex_type_key}_#{choice.name.upcase} = \"#{choice.name}\";" }
        if choice.type
          wtf(file) { " /* Expects at $_inject: #{choice.type} */" }
        else
          wtf(file) { " /* Nothing expected at $_inject. Please, provide null */" }
        end
      end if complex_type.choices
      totalArguments = Array.new
      if complex_type.choices
        totalArguments << Argument.new("_choice", nil, nil)
        totalArguments << Argument.new("_inject", nil, nil)
      end
      totalArguments << complex_type.arguments
      wtf(file) { "\n\tpublic static function create_#{complex_type_key}(#{totalArguments.join(", ")}, $_namespace = true) {\n" }
    end
    wtf(file) { "\t\t$__namespace = $_namespace ? \"#{@namespace}:\" : \"\";\n" }
    wtf(file) { "\t\t$_res = new #{@xsd_class_name}();\n" }
    if complex_type.choices
      wtf(file) { "\t\t$_res->_query .= \"<$__namespace$_choice>\";\n" }
      wtf(file) { "\t\tif ($_inject) {\n" }
      wtf(file) { "\t\t\t$_res->_dependencies = $_inject->dependencies();\n" }
      wtf(file) { "\t\t\tif (get_class($_res) != get_class($_inject)) {\n" }
      wtf(file) { "\t\t\t\t$_res->_dependencies[] = \"xmlns:\" . $_inject->xml_namespace() . \"=\\\"\" . $_inject->xml_referer() . \"\\\"\";\n" }
      wtf(file) { "\t\t\t}\n" }
      wtf(file) { "\t\t\tif (is_string($_inject)) {\n" }
      wtf(file) { "\t\t\t\t$_res->_query .= $_inject;\n" }
      wtf(file) { "\t\t\t} else if ($_inject) {\n" }
      wtf(file) { "\t\t\t\t$_res->_query .= $_inject->query();\n" }
      wtf(file) { "\t\t\t\tif (get_class($_res) != get_class($_inject)) {\n" }
      wtf(file) { "\t\t\t\t\t$_res->_dependencies[] = \"xmlns:\" . $_inject->xml_namespace() . \"=\\\"\" . $_inject->xml_referer() . \"\\\"\";\n" }
      wtf(file) { "\t\t\t\t}\n" }
      wtf(file) { "\t\t\t\t$_res->_dependencies = array_merge($_res->_dependencies, $_inject->dependencies());\n" }
      wtf(file) { "\t\t\t}\n" }
      wtf(file) { "\t\t}\n" }
      wtf(file) { "\t\t$_res->_query .= \"</$__namespace$_choice>\";\n" }
    end
    for argument in complex_type.arguments
      wtf(file) { "\t\tif (is_string($#{argument.name})) {\n" }
      wtf(file) { "\t\t\t$_res->_query .= \"<${__namespace}#{argument.name}>$#{argument.name}</${__namespace}#{argument.name}>\";\n" }
      wtf(file) { "\t\t} else if ($#{argument.name}) {\n" }
      wtf(file) { "\t\t\t$_res->_query .= \"<${__namespace}#{argument.name}>\" . $#{argument.name}->query() . \"</${__namespace}#{argument.name}>\";\n" }
      wtf(file) { "\t\t\tif (get_class($_res) != get_class($#{argument.name})) {\n" }
      wtf(file) { "\t\t\t\t$_res->_dependencies[] = \"xmlns:\" . $#{argument.name}->xml_namespace() . \"=\\\"\" . $#{argument.name}->xml_referer() . \"\\\"\";\n" }
      wtf(file) { "\t\t\t}\n" }
      wtf(file) { "\t\t\t$_res->_dependencies = array_merge($_res->_dependencies, $#{argument.name}->dependencies());\n" }
      wtf(file) { "\t\t}\n" }
    end
    wtf(file) { "\t\treturn $_res;\n" }
  end

  def write_complex_type_with_choices(file, complex_type_key, complex_type)
    wtf(file) { "\n" }
    for choice in complex_type.choices
      wtf(file) { "\tconst #{complex_type_key}_#{choice.name.upcase} = \"#{choice.name}\";" }
      if choice.type
        wtf(file) { " /* Expects at $_inject: #{choice.type} */\n" }
      else
        wtf(file) { " /* Nothing expected at $_inject. Please, provide null */\n" }
      end
    end
    wtf(file) { "\tpublic static function create_#{complex_type_key}($_choice, $_inject, $_namespace = true) {\n" }
    wtf(file) { "\t\t$__namespace = $_namespace ? \"#{@namespace}:\" : \"\";\n" }
    wtf(file) { "\t\t$_res = new #{@xsd_class_name}();\n" }
    wtf(file) { "\t\t$_res->_query .= \"<$__namespace$_choice>\";\n" }
    wtf(file) { "\t\tif ($_inject && is_string($_inject)) {\n" }
    wtf(file) { "\t\t\t$_res->_query .= $_inject;\n" }
    wtf(file) { "\t\t} else if ($_inject) {\n" }
    wtf(file) { "\t\t\t$_res->_query .= $_inject->query();\n" }
    wtf(file) { "\t\t\tif (get_class($_res) != get_class($_inject)) {\n" }
    wtf(file) { "\t\t\t\t$_res->_dependencies[] = \"xmlns:\" . $_inject->xml_namespace() . \"=\\\"\" . $_inject->xml_referer() . \"\\\"\";\n" }
    wtf(file) { "\t\t\t}\n" }
    wtf(file) { "\t\t\t$_res->_dependencies = array_merge($_res->_dependencies, $_inject->dependencies());\n" }
    wtf(file) { "\t\t}\n" }
    wtf(file) { "\t\t$_res->_query .= \"</$__namespace$_choice>\";\n" }
    wtf(file) { "\t\treturn $_res;\n" }
  end

  def write_complex_type_with_simple_content(file, complex_type_key, complex_type)
    if complex_type.simple_content.attributes.empty?
      wtf(file) { "\n\tpublic static function create_#{complex_type_key}($_namespace = true) {\n" }
    else
      wtf(file) { "\n\tpublic static function create_#{complex_type_key}(#{complex_type.simple_content.attributes.join(", ")}, $_namespace = true) {\n" }
    end
    wtf(file) { "\t\t$__namespace = $_namespace ? \"#{@namespace}:\" : \"\";\n" }
  end

  def write_complex_type_with_attributes(file, complex_type_key, complex_type)
    if complex_type.attributes.empty?
      wtf(file) { "\n\tpublic static function create_#{complex_type_key}($_namespace = true) {\n" }
    else
      wtf(file) { "\n\tpublic static function create_#{complex_type_key}(#{complex_type.attributes.join(", ")}, $_namespace = true) {\n" }
    end
    wtf(file) { "\t\t$__namespace = $_namespace ? \"#{@namespace}:\" : \"\";\n" }
  end

  def write_xml_generator(file)
    wtf(file) { "\n\t//////////////// Intended public functions ////////////////\n" }
    wtf(file) { "\n\t/**\n" }
    wtf(file) { "\t * Returns a proper XML document.\n" }
    wtf(file) { "\t *\n" }
    wtf(file) { "\t * You will typically call this function on your last node, for getting a\n" }
    wtf(file) { "\t * complete XML request.\n" }
    wtf(file) { "\t */" }
    wtf(file) { "\n\tpublic function generateXML($_inject = null, $_namespace = false) {\n" }
    wtf(file) { "\t\t$__namespace = $_namespace ? \"#{@namespace}:\" : \"\";\n" }
    wtf(file) { "\t\t$dependencies = array_unique($this->_dependencies);\n" }
    wtf(file) { "\t\t$dependencyList = implode(\" \", $dependencies);\n" }
    wtf(file) { "\t\t$res = \"<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\" standalone=\\\"no\\\"?>\";\n" }
    wtf(file) { "\t\t$myself = \"\";\n" }
    wtf(file) { "\t\tif ($_namespace) {\n" }
    wtf(file) { "\t\t\t$myself = \"xmlns:#{@namespace}=\\\"#{@referer}\\\"\";\n" }
    wtf(file) { "\t\t} else {\n" }
    wtf(file) { "\t\t\t$myself = \"xmlns=\\\"#{@referer}\\\"\";\n" }
    wtf(file) { "\t\t}\n" }
    wtf(file) { "\t\tif (empty($dependencyList)) {\n" }
    wtf(file) { "\t\t\t$res .= \"<${__namespace}#{@xsd_class_name} $myself>\";\n" }
    wtf(file) { "\t\t} else {\n" }
    wtf(file) { "\t\t\t$res .= \"<${__namespace}#{@xsd_class_name} $myself $dependencyList>\";\n" }
    wtf(file) { "\t\t}\n" }
    wtf(file) { "\t\tif ($_inject) {\n" }
    wtf(file) { "\t\t\t$res .= $_inject->query();\n" }
    wtf(file) { "\t\t}\n" }
    wtf(file) { "\t\t$res .= $this->_query;\n" }
    wtf(file) { "\t\t$res .= \"</${__namespace}#{@xsd_class_name}>\";\n" }
    wtf(file) { "\t\treturn $res;\n" }
    wtf(file) { "\t}\n" }
    wtf(file) { "\n\t/**\n" }
    wtf(file) { "\t * Capable of writing the XML to a web browser by sending the content-type header.\n" }
    wtf(file) { "\t */" }
    wtf(file) { "\n\tpublic static function debugXML($xml) {\n" }
    wtf(file) { "\t\theader(\"content-type: text/xml\");\n" }
    wtf(file) { "\t\techo $xml;\n" }
    wtf(file) { "\t}\n" }
    wtf(file) { "\n\t//////////////// Private usage. You don't need them ////////////////\n" }
    wtf(file) { "\n\t/**\n" }
    wtf(file) { "\t * Returns dependencies.\n" }
    wtf(file) { "\t */" }
    wtf(file) { "\n\tpublic function dependencies() {\n" }
    wtf(file) { "\t\treturn $this->_dependencies;\n" }
    wtf(file) { "\t}\n" }
    wtf(file) { "\n\t/**\n" }
    wtf(file) { "\t * Returns the current query.\n" }
    wtf(file) { "\t */" }
    wtf(file) { "\n\tpublic function query() {\n" }
    wtf(file) { "\t\treturn $this->_query;\n" }
    wtf(file) { "\t}\n" }
    wtf(file) { "\n\t/**\n" }
    wtf(file) { "\t * Returns the referer of this XML entity.\n" }
    wtf(file) { "\t */" }
    wtf(file) { "\n\tpublic function xml_referer() {\n" }
    wtf(file) { "\t\treturn \"#{@referer}\";\n" }
    wtf(file) { "\t}\n" }
    wtf(file) { "\n\t/**\n" }
    wtf(file) { "\t * Returns the namespace of this XML entity.\n" }
    wtf(file) { "\t */" }
    wtf(file) { "\n\tpublic function xml_namespace() {\n" }
    wtf(file) { "\t\treturn \"#{@namespace}\";\n" }
    wtf(file) { "\t}\n" }
    wtf(file) { "\n\t//////////////// Autogenerated functions follows ////////////////\n" }
  end

end
