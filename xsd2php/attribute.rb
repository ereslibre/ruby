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

class Attribute

  attr_reader :name, :type, :minOccurs, :maxOccurs

  def initialize(name, type, contents)
    @name = name
    @type = type
    @minOccurs = contents["minOccurs"] if contents.has_key? "minOccurs"
    @maxOccurs = contents["maxOccurs"] if contents.has_key? "maxOccurs"
  end

  def to_s
    return "$#{@name} = \"\"" if @minOccurs == "0"
    "$#{@name}"
  end

end
