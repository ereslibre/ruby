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

require "attribute"

class ComplexType

  attr_reader :name, :sequence, :attributes

  def initialize(name, contents)
    @name = name
    @attributes = Array.new
    for key, value in contents
      if key == "sequence"
        subContents = value[0]["element"] # TODO: Check for "any" too
        for key, value in subContents
          @attributes << Attribute.new(key, value["type"])
        end if subContents
      elsif key == "simpleContent"
      elsif key == "choice"
      elsif key == "attribute"
      elsif key == "mixed"
      elsif key == "anyAttribute"
      end
    end
  end

end
