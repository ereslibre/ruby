#!/usr/bin/env ruby
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

require "fileutils"

if ARGV.size != 5
	puts "usage: #$0 username group ownerName repositoryName repositoryDescription"
	puts "\t>> username\t\t\tThe username for whom we are creating the repository"
	puts "\t>> group\t\t\tThe group of the username for whom we are creating the repository"
	puts "\t>> ownerName\t\t\tThe owner name in long format. Example: \"Rafael Fernández López\""
	puts "\t>> repositoryName\t\tThe name of the repository"
	puts "\t>> repositoryDescription\tThe description of the repository. Example: \"My super-cool project\""
	Process.exit
end

current_user = `whoami`.slice /^(.*)\n$/, 1	# whoami returns "username\n"

if current_user != "root"
	puts "Please, run the script as the root user"
	Process.exit
end

username = ARGV[0]
group = ARGV[1]
owner_name = ARGV[2]
repository_name = ARGV[3]
repository_desc = ARGV[4]
repository_path = "/home/#{username}/#{repository_name}"

pwd = FileUtils.pwd

# Repository creation
FileUtils.mkdir_p repository_path
FileUtils.cd repository_path
`git --bare init`

# Make it visible for git-daemon (git:// protocol)
FileUtils.touch "git-daemon-export-ok"

# Basic configuration and Make It Pretty (TM)
open("config", "a") { |f|
	f.puts "[gitweb]"
	f.puts "\towner = #{owner_name}"
	f.puts "[receive]"
	f.puts "\tdenyNonFastForwards = true"
}
File.truncate "description", 0
open("description", "a") { |f|
	f.puts repository_desc
}

# chown to the target username
FileUtils.chown_R username, group, repository_path

# Add it to the git cache
git_cache = "/var/cache/git/#{username}"
FileUtils.mkdir_p git_cache
FileUtils.ln_s repository_path, "#{git_cache}/#{repository_name}"

# Let's go back to the directory we were at
FileUtils.cd pwd
