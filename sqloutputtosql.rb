#!/usr/bin/env ruby

f = File.open 'hola.txt', 'r'
o = File.open 'adios.sql', 'w'

f.each_line do |l|
  l =~ /\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\w+)\s*\|\s*([^\s|]+)/
  o.puts "update domain_provider set provider = '#{$3}', provider_id = '#{$4}' where id = #{$1};";
end
