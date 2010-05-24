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

  attr_reader :base, :min_length, :max_length, :enumeration, :pattern, :min_inclusive, :max_inclusive

  def initialize(restriction)
    @base = restriction["base"]
    if @base == "token"
      @min_length = restriction["minLength"][0]["value"] if restriction.has_key?("minLength")
      @max_length = restriction["maxLength"][0]["value"] if restriction.has_key?("maxLength")
      @length = restriction["length"][0]["value"] if restriction.has_key?("length")
      @pattern = restriction["pattern"][0]["value"] if restriction.has_key?("pattern")
    elsif @base == "unsignedShort"
      @min_inclusive = restriction["minInclusive"][0]["value"] if restriction.has_key?("minInclusive")
      @max_inclusive = restriction["maxInclusive"][0]["value"] if restriction.has_key?("maxInclusive")
    elsif @base == "normalizedString"
      @min_length = restriction["minLength"][0]["value"] if restriction.has_key?("minLength")
      @max_length = restriction["maxLength"][0]["value"] if restriction.has_key?("maxLength")
    end
    if restriction.has_key?("enumeration")
      @enumeration = Array.new
      for value in restriction["enumeration"]
        @enumeration << value["value"]
      end
    end
  end

end
