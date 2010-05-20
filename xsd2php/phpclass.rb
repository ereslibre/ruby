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

  attr_reader :xsdClassName, :className, :simpleTypes, :elements

  def initialize(destination, contents)
    @destination = destination
    @xsdClassName = contents["targetNamespace"].slice(/^((.*):)*([a-zA-Z0-9_]*)/, 3)
    @className = @xsdClassName.downcase.capitalize
    @simpleTypes = Hash.new
    @complexTypes = Hash.new
    @elements = Array.new
    contents.each { | key, value |
      if key == "simpleType"
        value.each { | currKey, currValue |
          @simpleTypes[currKey] = SimpleType.new(currKey, currValue["restriction"])
        }
      elsif key == "complexType"
        value.each { | currKey, currValue |
          @complexTypes[currKey] = ComplexType.new(currKey, currValue)
        }
      elsif key == "element"
        value.each { | currKey, currValue |
          @elements << Element.new(currKey, currValue["type"])
        }
      end
    }
  end

  def writeClass(phpClasses)
    file = File.new("#{@destination}/#{@className.downcase}.php", "w")
    writeToFile(file) { "<?php\n\n" }
    writeHeader(file)
    writeToFile(file) { "class #{@className}\n{\n\tprivate $query = \"\";\n\n\n" }
    writeElements(file, phpClasses)
    writeXMLGenerator(file)
    file.close
  end

  private

  def writeElements(file, phpClasses)
    @elements.each { |element|
      writeToFile(file) { "\tpublic function do#{element.name.capitalize}() {\n"  }
      writeToFile(file) { "\t}\n\n" }
    }
  end

  def writeXMLGenerator(file)
    writeToFile(file) { "\tpublic function generateXML() {\n" }
    writeToFile(file) { "\t\t$res = \"<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?>\";\n" }
    writeToFile(file) { "\t\t$res += \"<epp xmlns=\\\"urn:ietf:params:xml:ns:epp-1.0\\\" " \
      "xmlns:domain=\\\"urn:ietf:params:xml:ns:domain-1.0\\\" " \
      "xmlns:es_creds=\\\"urn:red.es:xml:ns:es_creds-1.0\\\">\";\n" }
    writeToFile(file) { "\t\t$res += \"<command>\";\n" }
    writeToFile(file) { "\t\t$res += $query;\n" }
    writeToFile(file) { "\t\t$res += \"</command>\";\n" }
    writeToFile(file) { "\t\treturn $res;\n" }
    writeToFile(file) { "\t}\n" }
  end

end
