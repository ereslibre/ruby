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

class ComplexType

  attr_reader :name, :arguments, :choices

  def initialize(name, contents)
    @name = name
    for key, value in contents
      if key == "sequence"
        @arguments = Array.new
        sub_contents = value[0]["element"] # TODO: Check for "any" too
        for key, value in sub_contents
          @arguments << Argument.new(key, value["type"], value)
        end if sub_contents
      elsif key == "simpleContent"
      elsif key == "choice"
        @choices = Array.new
        sub_contents = value[0]["element"]
        for key, value in sub_contents
          @choices << Argument.new(key, value["type"], value)
        end
      elsif key == "attribute"
      elsif key == "mixed"
      elsif key == "anyAttribute"
      end
    end
  end

end
