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

class Element

  attr_reader :name, :type, :xsd_class_name

  def initialize(name, type, xsd_class_name)
    @name = name
    @xsd_class_name = xsd_class_name
    if type.is_a? String
      @type = type
    else
      if type.has_key? "complexType" # TODO: Possibly check other types
        @type = type["complexType"][0]["complexContent"][0]["extension"][0]["base"]
      end
    end
  end

end
