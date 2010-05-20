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

class Restriction

  attr_reader :base, :minLength, :maxLength, :enumeration, :pattern, :minInclusive, :maxInclusive

  def initialize(restriction)
    @base = restriction["base"]
    if @base == "token"
      @minLength = restriction["minLength"][0]["value"] if restriction.has_key?("minLength")
      @maxLength = restriction["maxLength"][0]["value"] if restriction.has_key?("maxLength")
      @length = restriction["length"][0]["value"] if restriction.has_key?("length")
      @pattern = restriction["pattern"][0]["value"] if restriction.has_key?("pattern")
    elsif @base == "unsignedShort"
      @minInclusive = restriction["minInclusive"][0]["value"] if restriction.has_key?("minInclusive")
      @maxInclusive = restriction["maxInclusive"][0]["value"] if restriction.has_key?("maxInclusive")
    elsif @base == "normalizedString"
      @minLength = restriction["minLength"][0]["value"] if restriction.has_key?("minLength")
      @maxLength = restriction["maxLength"][0]["value"] if restriction.has_key?("maxLength")      
    end
    if restriction.has_key?("enumeration")
      @enumeration = Array.new
      restriction["enumeration"].each { | value |
        @enumeration << value["value"]
      }
    end
  end

end
