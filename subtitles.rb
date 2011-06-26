#!/usr/bin/env ruby

# Please note that it is necessary to have installed
# 'periscope' in order for this script to work.
#
# You can download periscope from here:
# http://code.google.com/p/periscope/

EXTENSIONS = ['avi']

def usage
  puts "usage: #{$0} path language"
  puts "\tlanguage is of type: en, de, es..."
end

usage if ARGV.length < 2

$path = ARGV[0]
$language = ARGV[1]

def explore(path)
  Dir.foreach(path) { |x|
    next if x == '.' or x == '..'
    curr_path = "#{path}/#{x}"
    if File.directory? curr_path
      Dir.chdir(curr_path) {
        explore curr_path
      }
    elsif File.file? curr_path
      EXTENSIONS.each { |ext|
        if curr_path =~ /[^.]\.#{ext}$/
          if system "periscope -f -l \"#{$language}\" \"#{curr_path}\" &> /dev/null"
            puts "*** File #{File.basename curr_path}"
          else
            puts "!!! File #{File.basename curr_path}"
          end
        else
          puts "!!! File #{File.basename curr_path} extension could not be handled"
        end
      }
    else
      puts "!!! Could not work with #{File.basename curr_path}"
    end
  }
end

Dir.chdir($path) {
  explore $path
}
