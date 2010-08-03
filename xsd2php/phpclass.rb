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
    if PHPClass.is_simple_type @type
        printType = "#{@type} (simple type)"
    else
        printType = "#{@type} (complex type)"
    end
    if @type
      "$#{@name} /* #{printType} */"
    else
      "$#{@name}"
    end
  end

end

class Attribute

  def to_s
    if PHPClass.is_simple_type @type
        printType = "#{@type} (simple type)"
    elsif PHPClass.is_complex_type @type
        printType = "#{@type} (complex type)"
    else
        printType = nil
    end
    if @default and printType
        "$#{@name} = \"#{@default}\" /* #{printType} */"
    elsif !@default and printType
        "$#{@name} /* #{printType} */"
    elsif @default and !printType
        "$#{@name} = \"#{@default}\""
    else
        "$#{@name}"
    end
  end

end

class CodeAttribute < Attribute

    def to_s
        "#{@name}=\\\"$#{@name}Attr\\\""
    end

    def to_s2
        if PHPClass.is_simple_type @type
            printType = "#{@type} (simple type)"
        elsif PHPClass.is_complex_type @type
            printType = "#{@type} (complex type)"
        else
            printType = nil
        end
        if @default
            if printType
                "$#{@name}Attr = \"#{@default}\" /* #{printType} */"
            else
                "$#{@name}Attr = \"#{@default}\""
            end
        elsif !@use == "required"
            if printType
                "$#{@name}Attr = null /* #{printType} */"
            else
                "$#{@name}Attr = null"
            end
        else
            if printType
                "$#{@name}Attr /* #{printType} */"
            else
                "$#{@name}Attr"
            end
        end
    end

end

class PHPClass

  attr_reader :xsd_class_name, :namespace, :referer, :elements

  @@simple_types = Hash.new
  @@complex_types = Hash.new

  def self.is_complex_type(type)
      @@complex_types.has_key? type
  end

  def self.is_simple_type(type)
      @@simple_types.has_key? type
  end

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
    wtf(file) { "\n\tprivate $_query = \"\";" }
    wtf(file) { "\n\tprivate $_attributes = \"\";\n" }
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
      wtf(file) { "\t\t$__res = new #{@xsd_class_name}();\n" }
      wtf(file) { "\t\t$__res->_query = \"<${__namespace}#{element.name}>\";\n" }
      wtf(file) { "\t\tif (is_string($#{element.name})) {\n" }
      wtf(file) { "\t\t\t$__res->_query .= $#{element.name};\n" }
      wtf(file) { "\t\t} else if ($#{element.name}) {\n" }
      wtf(file) { "\t\t\t$__res->_query .= $#{element.name}->query();\n" }
      wtf(file) { "\t\t\t$__res->_dependencies = $#{element.name}->dependencies();\n" }
      wtf(file) { "\t\t\tif (get_class($__res) != get_class($#{element.name})) {\n" }
      wtf(file) { "\t\t\t\t$__res->_dependencies[] = \"xmlns:\" . $#{element.name}->xml_namespace() . \"=\\\"\" . $#{element.name}->xml_referer() . \"\\\"\";\n" }
      wtf(file) { "\t\t\t}\n" }
      wtf(file) { "\t\t}\n" }
      wtf(file) { "\t\t$__res->_query .= \"</${__namespace}#{element.name}>\";\n" }
      wtf(file) { "\t\treturn $__res;\n" }
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
    if complex_type.attributes
      attributeList = Array.new
      for attribute in complex_type.attributes
        attributeList << CodeAttribute.new(attribute.name, attribute.type, attribute.use, attribute.default)
      end
    end

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
      if attributeList
        args = totalArguments.concat(attributeList.map { |e| e.to_s2 }).join(", ")
      else
        args = totalArguments.join(", ")
      end
      wtf(file) { "\n\tpublic static function create_#{complex_type_key}(#{args}, $_namespace = true) {\n" }
    end
    wtf(file) { "\t\t$__namespace = $_namespace ? \"#{@namespace}:\" : \"\";\n" }
    wtf(file) { "\t\t$__res = new #{@xsd_class_name}();\n" }
    if complex_type.choices
      wtf(file) { "\t\t$__res->_query .= \"<$__namespace$_choice>\";\n" }
      wtf(file) { "\t\tif ($_inject) {\n" }
      wtf(file) { "\t\t\t$__res->_dependencies = $_inject->dependencies();\n" }
      wtf(file) { "\t\t\tif (get_class($__res) != get_class($_inject)) {\n" }
      wtf(file) { "\t\t\t\t$__res->_dependencies[] = \"xmlns:\" . $_inject->xml_namespace() . \"=\\\"\" . $_inject->xml_referer() . \"\\\"\";\n" }
      wtf(file) { "\t\t\t}\n" }
      wtf(file) { "\t\t\tif (is_string($_inject)) {\n" }
      wtf(file) { "\t\t\t\t$__res->_query .= $_inject;\n" }
      wtf(file) { "\t\t\t} else if ($_inject) {\n" }
      wtf(file) { "\t\t\t\t$__res->_query .= $_inject->query();\n" }
      wtf(file) { "\t\t\t\tif (get_class($__res) != get_class($_inject)) {\n" }
      wtf(file) { "\t\t\t\t\t$__res->_dependencies[] = \"xmlns:\" . $_inject->xml_namespace() . \"=\\\"\" . $_inject->xml_referer() . \"\\\"\";\n" }
      wtf(file) { "\t\t\t\t}\n" }
      wtf(file) { "\t\t\t\t$__res->_dependencies = array_merge($__res->_dependencies, $_inject->dependencies());\n" }
      wtf(file) { "\t\t\t}\n" }
      wtf(file) { "\t\t}\n" }
      wtf(file) { "\t\t$__res->_query .= \"</$__namespace$_choice>\";\n" }
    end
    for argument in complex_type.arguments
      wtf(file) { "\t\tif (is_string($#{argument.name})) {\n" }
      wtf(file) { "\t\t\t$__res->_query .= \"<${__namespace}#{argument.name}>$#{argument.name}</${__namespace}#{argument.name}>\";\n" }
      wtf(file) { "\t\t} else if (is_array($#{argument.name})) {\n" }
      wtf(file) { "\t\t\tforeach ($#{argument.name} as $_#{argument.name}) {\n" }
      wtf(file) { "\t\t\t\tif (is_string($_#{argument.name})) {\n" }
      wtf(file) { "\t\t\t\t\t$__res->_query .= \"<${__namespace}#{argument.name}>\";\n" }
      wtf(file) { "\t\t\t\t\t$__res->_query .= $_#{argument.name};\n" }
      wtf(file) { "\t\t\t\t} else if ($_#{argument.name}) {\n" }
      wtf(file) { "\t\t\t\t\t$__attributes = $_#{argument.name}->attributes();\n" }
      wtf(file) { "\t\t\t\t\t$__res->_query .= \"<${__namespace}#{argument.name}${__attributes}>\";\n" }
      wtf(file) { "\t\t\t\t\t$__res->_query .= $_#{argument.name}->query();\n" }
      wtf(file) { "\t\t\t\t}\n" }
      wtf(file) { "\t\t\t\t$__res->_query .= \"</${__namespace}#{argument.name}>\";\n" }
      wtf(file) { "\t\t\t}\n" }
      wtf(file) { "\t\t} else if ($#{argument.name}) {\n" }
      wtf(file) { "\t\t\t$__query = $#{argument.name}->query();\n" }
      wtf(file) { "\t\t\t$__attributes = $#{argument.name}->attributes();\n" }
      wtf(file) { "\t\t\t$__res->_query .= \"<${__namespace}#{argument.name}${__attributes}>${__query}</${__namespace}#{argument.name}>\";\n" }
      wtf(file) { "\t\t\tif (get_class($__res) != get_class($#{argument.name})) {\n" }
      wtf(file) { "\t\t\t\t$__res->_dependencies[] = \"xmlns:\" . $#{argument.name}->xml_namespace() . \"=\\\"\" . $#{argument.name}->xml_referer() . \"\\\"\";\n" }
      wtf(file) { "\t\t\t}\n" }
      wtf(file) { "\t\t\t$__res->_dependencies = array_merge($__res->_dependencies, $#{argument.name}->dependencies());\n" }
      wtf(file) { "\t\t}\n" }
    end
    for attribute in attributeList
      wtf(file) { "\t\tif (is_string($#{attribute.name}Attr)) {\n" }
      wtf(file) { "\t\t\t$__res->_attributes .= \" #{attribute.name}=\\\"$#{attribute.name}Attr\\\"\";\n" }
      wtf(file) { "\t\t}\n" }
      wtf(file) { "\t\treturn $__res;\n" }
    end if attributeList
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
    wtf(file) { "\t\t$__res = new #{@xsd_class_name}();\n" }
    wtf(file) { "\t\t$__res->_query .= \"<$__namespace$_choice>\";\n" }
    wtf(file) { "\t\tif ($_inject && is_string($_inject)) {\n" }
    wtf(file) { "\t\t\t$__res->_query .= $_inject;\n" }
    wtf(file) { "\t\t} else if ($_inject) {\n" }
    wtf(file) { "\t\t\t$__res->_query .= $_inject->query();\n" }
    wtf(file) { "\t\t\tif (get_class($__res) != get_class($_inject)) {\n" }
    wtf(file) { "\t\t\t\t$__res->_dependencies[] = \"xmlns:\" . $_inject->xml_namespace() . \"=\\\"\" . $_inject->xml_referer() . \"\\\"\";\n" }
    wtf(file) { "\t\t\t}\n" }
    wtf(file) { "\t\t\t$__res->_dependencies = array_merge($__res->_dependencies, $_inject->dependencies());\n" }
    wtf(file) { "\t\t}\n" }
    wtf(file) { "\t\t$__res->_query .= \"</$__namespace$_choice>\";\n" }
    wtf(file) { "\t\treturn $__res;\n" }
  end

  def write_complex_type_with_simple_content(file, complex_type_key, complex_type)
    if complex_type.simple_content.attributes.empty?
      wtf(file) { "\n\tpublic static function create_#{complex_type_key}() {\n" }
    else
      elements = Array.new
      for attribute in complex_type.simple_content.attributes
          elements << attribute
          newAttribute = Attribute.new("#{attribute.name}Attr", attribute.type, attribute.use, attribute.default)
          newAttribute.type = nil
          elements << newAttribute
          attribute.default = nil
      end
      wtf(file) { "\n\tpublic static function create_#{complex_type_key}(#{elements.join(", ")}) {\n" }
    end
    wtf(file) { "\t\t$__res = new #{@xsd_class_name}();\n" }
    for attribute in complex_type.simple_content.attributes
        wtf(file) { "\t\tif (is_string($#{attribute.name})) {\n" }
        wtf(file) { "\t\t\t$__res->_query .= $#{attribute.name};\n" }
        wtf(file) { "\t\t} else if ($#{attribute.name}) {\n" }
        wtf(file) { "\t\t\t$__res->_query .= $#{attribute.name}->query();\n" }
        wtf(file) { "\t\t\tif (get_class($__res) != get_class($#{attribute.name})) {\n" }
        wtf(file) { "\t\t\t\t$__res->_dependencies[] = \"xmlns:\" . $#{attribute.name}->xml_namespace() . \"=\\\"\" . $#{attribute.name}->xml_referer() . \"\\\"\";\n" }
        wtf(file) { "\t\t\t}\n" }
        wtf(file) { "\t\t\t$__res->_dependencies = array_merge($__res->_dependencies, $#{attribute.name}->dependencies());\n" }
        wtf(file) { "\t\t}\n" }
        wtf(file) { "\t\tif (is_string($#{attribute.name}Attr)) {\n" }
        wtf(file) { "\t\t\t$__res->_attributes .= \" #{attribute.name}=\\\"$#{attribute.name}Attr\\\"\";\n" }
        wtf(file) { "\t\t}\n" }
    end
    wtf(file) { "\t\treturn $__res;\n" }
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
    wtf(file) { "\t\t$__dependencies = array_unique($this->_dependencies);\n" }
    wtf(file) { "\t\t$__dependencyList = implode(\" \", $__dependencies);\n" }
    wtf(file) { "\t\t$__res = \"<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\" standalone=\\\"no\\\"?>\\n\";\n" }
    wtf(file) { "\t\t$__myself = \"\";\n" }
    wtf(file) { "\t\tif ($_namespace) {\n" }
    wtf(file) { "\t\t\t$__myself = \"xmlns:#{@namespace}=\\\"#{@referer}\\\"\";\n" }
    wtf(file) { "\t\t} else {\n" }
    wtf(file) { "\t\t\t$__myself = \"xmlns=\\\"#{@referer}\\\"\";\n" }
    wtf(file) { "\t\t}\n" }
    wtf(file) { "\t\tif (empty($__dependencyList)) {\n" }
    wtf(file) { "\t\t\t$__res .= \"<${__namespace}#{@xsd_class_name} $__myself>\";\n" }
    wtf(file) { "\t\t} else {\n" }
    wtf(file) { "\t\t\t$__res .= \"<${__namespace}#{@xsd_class_name} $__myself $__dependencyList>\";\n" }
    wtf(file) { "\t\t}\n" }
    wtf(file) { "\t\tif ($_inject) {\n" }
    wtf(file) { "\t\t\t$__res .= $_inject->query();\n" }
    wtf(file) { "\t\t}\n" }
    wtf(file) { "\t\t$__res .= $this->_query;\n" }
    wtf(file) { "\t\t$__res .= \"</${__namespace}#{@xsd_class_name}>\";\n" }
    wtf(file) { "\t\treturn $__res;\n" }
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
    wtf(file) { "\t * Returns the current attributes.\n" }
    wtf(file) { "\t */" }
    wtf(file) { "\n\tpublic function attributes() {\n" }
    wtf(file) { "\t\treturn $this->_attributes;\n" }
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
