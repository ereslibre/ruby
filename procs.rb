#!/usr/bin/env ruby

def callbacks(procs)
	puts "Calling to ':starting'"
	procs[:starting].call
	puts "Calling to ':working'"
	procs[:working].call
	puts "Calling to ':finishing'"
	procs[:finishing].call
end

callbacks(:starting => Proc.new { puts "Starting" },
          :working => Proc.new { puts "Working" },
          :finishing => Proc.new { puts "Finishing" })
